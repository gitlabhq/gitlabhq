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
import { DELETE_POD_ACTION } from '~/environments/constants';
import { getAge } from '~/kubernetes_dashboard/helpers/k8s_integration_helper';
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
      watchLoading(isLoading) {
        this.$emit('loading', isLoading);
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
          value: this.countPodsByPhase(STATUS_RUNNING),
          title: STATUS_LABELS[STATUS_RUNNING],
        },
        {
          value: this.countPodsByPhase(STATUS_PENDING),
          title: STATUS_LABELS[STATUS_PENDING],
        },
        {
          value: this.countPodsByPhase(STATUS_SUCCEEDED),
          title: STATUS_LABELS[STATUS_SUCCEEDED],
        },
        {
          value: this.countPodsByPhase(STATUS_FAILED),
          title: STATUS_LABELS[STATUS_FAILED],
        },
      ];
    },
    loading() {
      return this.$apollo?.queries?.k8sPods?.loading;
    },
    podsCount() {
      return this.k8sPods?.length || 0;
    },
    filteredPods() {
      return this.k8sPods.filter((pod) => {
        const matchesStatus = !this.statusFilter || pod.status === this.statusFilter;
        const matchesSearch = !this.podsSearch || pod.name.includes(this.podsSearch);
        return matchesStatus && matchesSearch;
      });
    },
  },
  methods: {
    countPodsByPhase(phase) {
      const filteredPods = this.k8sPods?.filter((item) => item.status === phase) || [];

      const hasFailedState = Boolean(phase === STATUS_FAILED && filteredPods.length);
      this.$emit('update-failed-state', { pods: hasFailedState });

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
      <workload-stats v-if="podStats" :stats="podStats" class="gl-mt-3" @select="filterPods" />

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

      <workload-table
        v-if="k8sPods"
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
