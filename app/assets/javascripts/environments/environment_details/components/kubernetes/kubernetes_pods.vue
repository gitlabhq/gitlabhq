<script>
import { GlTab, GlLoadingIcon, GlBadge, GlSearchBoxByType, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  STATUS_RUNNING,
  STATUS_PENDING,
  STATUS_SUCCEEDED,
  STATUS_FAILED,
  STATUS_LABELS,
  PODS_TABLE_FIELDS,
} from '~/kubernetes_dashboard/constants';
import {
  DELETE_POD_ACTION,
  CLUSTER_HEALTH_SUCCESS,
  CLUSTER_HEALTH_ERROR,
  CLUSTER_HEALTH_NEEDS_ATTENTION,
  CLUSTER_HEALTH_UNKNOWN,
} from '~/environments/constants';
import { getAge, getPodStatusText } from '~/kubernetes_dashboard/helpers/k8s_integration_helper';
import WorkloadStats from '~/kubernetes_dashboard/components/workload_stats.vue';
import WorkloadTable from '~/kubernetes_dashboard/components/workload_table.vue';
import k8sPodsQuery from '~/environments/graphql/queries/k8s_pods.query.graphql';

export default {
  components: {
    GlTab,
    GlLoadingIcon,
    GlBadge,
    GlSearchBoxByType,
    GlSprintf,
    WorkloadStats,
    WorkloadTable,
  },
  apollo: {
    k8sPods: {
      query: k8sPodsQuery,
      variables() {
        return {
          configuration: this.configuration,
          namespace: this.namespace,
        };
      },
      update(data) {
        return (
          data?.k8sPods?.map((pod) => {
            return {
              name: pod.metadata.name,
              namespace: pod.metadata.namespace,
              status: pod.status.phase,
              age: getAge(pod.metadata.creationTimestamp),
              labels: pod.metadata.labels,
              annotations: pod.metadata.annotations,
              kind: s__('KubernetesDashboard|Pod'),
              spec: pod.spec,
              fullStatus: pod.status,
              statusText: getPodStatusText(pod.status),
              statusTooltip: pod.status.message,
              containers: pod.spec.containers,
              actions: [DELETE_POD_ACTION],
            };
          }) || []
        );
      },
      error(error) {
        this.error = error.message;
        this.$emit('cluster-error', this.error);
      },
    },
  },
  props: {
    configuration: {
      required: true,
      type: Object,
    },
    namespace: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      error: '',
      statusFilter: '',
      k8sPods: [],
      podsSearch: '',
    };
  },
  computed: {
    podStats() {
      if (!this.k8sPods) return null;

      return [
        {
          value: this.podsRunning,
          title: STATUS_LABELS[STATUS_RUNNING],
        },
        {
          value: this.podsPending,
          title: STATUS_LABELS[STATUS_PENDING],
        },
        {
          value: this.podsSucceeded,
          title: STATUS_LABELS[STATUS_SUCCEEDED],
        },
        {
          value: this.podsFailed,
          title: STATUS_LABELS[STATUS_FAILED],
        },
      ];
    },
    loading() {
      return this.$apollo?.queries?.k8sPods?.loading;
    },
    podsRunning() {
      return this.countPodsByPhase(STATUS_RUNNING);
    },
    podsPending() {
      return this.countPodsByPhase(STATUS_PENDING);
    },
    podsFailed() {
      return this.countPodsByPhase(STATUS_FAILED);
    },
    podsSucceeded() {
      return this.countPodsByPhase(STATUS_SUCCEEDED);
    },
    podsCount() {
      return this.k8sPods?.length || 0;
    },
    filteredPods() {
      return this.k8sPods.filter((pod) => {
        const matchesStatus = !this.statusFilter || pod.status === this.statusFilter;
        const matchesSearch = !this.podsSearch || this.search(this.podsSearch, pod.name);
        return matchesStatus && matchesSearch;
      });
    },
    podsHealthStatus() {
      if (this.loading) {
        return '';
      }

      if (!this.k8sPods.length) {
        return CLUSTER_HEALTH_UNKNOWN;
      }

      if (this.podsFailed > 0) {
        return CLUSTER_HEALTH_ERROR;
      }

      if (this.podsPending > 0) {
        return CLUSTER_HEALTH_NEEDS_ATTENTION;
      }

      return CLUSTER_HEALTH_SUCCESS;
    },
  },
  watch: {
    k8sPods() {
      this.$emit('update-cluster-state', this.podsHealthStatus);
    },
    podsSearch() {
      this.$refs.workloadTable?.resetPagination();
    },
    statusFilter() {
      this.$refs.workloadTable?.resetPagination();
    },
  },
  methods: {
    search(searchTerm, podName) {
      return podName.includes(searchTerm);
    },
    countPodsByPhase(phase) {
      const pods = this.k8sPods || [];

      const filteredPods = pods.filter((item) => {
        const matchesPhase = item.status === phase;
        if (!this.podsSearch) return matchesPhase;
        return matchesPhase && this.search(this.podsSearch, item.name);
      });

      return filteredPods.length;
    },
    onItemSelect(item) {
      this.$emit('select-item', item);
    },
    filterPods(status) {
      this.statusFilter = status;
    },
    onDeletePod(pod) {
      this.$emit('delete-pod', pod);
    },
  },
  i18n: {
    podsTitle: s__('Environment|Pods'),
    searchPlaceholder: s__('Environment|Search pod name'),
    filteredText: s__('Environment|Showing search results with the status %{status}.'),
  },
  PAGE_SIZE: 10,
  PODS_TABLE_FIELDS,
};
</script>
<template>
  <gl-tab>
    <template #title>
      {{ $options.i18n.podsTitle }}
      <gl-badge class="gl-tab-counter-badge">{{ podsCount }}</gl-badge>
    </template>

    <gl-loading-icon v-if="loading" />

    <template v-else-if="!error">
      <gl-search-box-by-type
        v-model.trim="podsSearch"
        :placeholder="$options.i18n.searchPlaceholder"
        class="gl-mt-5"
      />

      <div
        v-if="statusFilter && podsSearch"
        class="gl-mt-5 gl-rounded-base gl-bg-strong gl-p-5"
        data-testid="pods-filtered-message"
      >
        <gl-sprintf :message="$options.i18n.filteredText">
          <template #status>{{ statusFilter }}</template>
        </gl-sprintf>
      </div>

      <workload-stats v-if="podStats" :stats="podStats" class="gl-mt-3" @select="filterPods" />

      <workload-table
        v-if="k8sPods"
        ref="workloadTable"
        :items="filteredPods"
        :page-size="$options.PAGE_SIZE"
        :fields="$options.PODS_TABLE_FIELDS"
        class="gl-mt-8"
        @select-item="onItemSelect"
        @delete-pod="onDeletePod"
      />
    </template>
  </gl-tab>
</template>
