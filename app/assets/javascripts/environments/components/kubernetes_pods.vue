<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  STATUS_RUNNING,
  STATUS_PENDING,
  STATUS_SUCCEEDED,
  STATUS_FAILED,
  STATUS_LABELS,
} from '~/kubernetes_dashboard/constants';
import WorkloadStats from '~/kubernetes_dashboard/components/workload_stats.vue';
import k8sPodsQuery from '../graphql/queries/k8s_pods.query.graphql';

export default {
  components: {
    GlLoadingIcon,
    WorkloadStats,
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
        return data?.k8sPods || [];
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
  },
  methods: {
    countPodsByPhase(phase) {
      const filteredPods = this.k8sPods.filter((item) => item.status.phase === phase);

      const hasFailedState = Boolean(phase === STATUS_FAILED && filteredPods.length);
      this.$emit('update-failed-state', { pods: hasFailedState });

      return filteredPods.length;
    },
  },
  i18n: {
    podsTitle: s__('Environment|Pods'),
  },
};
</script>
<template>
  <div>
    <p class="gl-text-gray-500">{{ $options.i18n.podsTitle }}</p>

    <gl-loading-icon v-if="loading" />
    <workload-stats v-else-if="podStats && !error" :stats="podStats" />
  </div>
</template>
