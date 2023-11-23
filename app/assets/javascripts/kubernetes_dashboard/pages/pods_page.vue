<script>
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import WorkloadStats from '../components/workload_stats.vue';
import k8sPodsQuery from '../graphql/queries/k8s_dashboard_pods.query.graphql';
import {
  PHASE_RUNNING,
  PHASE_PENDING,
  PHASE_SUCCEEDED,
  PHASE_FAILED,
  STATUS_LABELS,
} from '../constants';

export default {
  components: {
    GlLoadingIcon,
    GlAlert,
    WorkloadStats,
  },
  inject: ['configuration'],
  apollo: {
    k8sPods: {
      query: k8sPodsQuery,
      variables() {
        return {
          configuration: this.configuration,
        };
      },
      update(data) {
        return data?.k8sPods || [];
      },
      error(err) {
        this.errorMessage = err?.message;
      },
    },
  },
  data() {
    return {
      errorMessage: '',
    };
  },
  computed: {
    podStats() {
      return [
        {
          value: this.countPodsByPhase(PHASE_RUNNING),
          title: STATUS_LABELS[PHASE_RUNNING],
        },
        {
          value: this.countPodsByPhase(PHASE_PENDING),
          title: STATUS_LABELS[PHASE_PENDING],
        },
        {
          value: this.countPodsByPhase(PHASE_SUCCEEDED),
          title: STATUS_LABELS[PHASE_SUCCEEDED],
        },
        {
          value: this.countPodsByPhase(PHASE_FAILED),
          title: STATUS_LABELS[PHASE_FAILED],
        },
      ];
    },
    loading() {
      return this.$apollo?.queries?.k8sPods?.loading;
    },
  },
  methods: {
    countPodsByPhase(phase) {
      const filteredPods = this.k8sPods?.filter((item) => item.status.phase === phase) || [];

      return filteredPods.length;
    },
  },
};
</script>
<template>
  <gl-loading-icon v-if="loading" />
  <gl-alert v-else-if="errorMessage" variant="danger" :dismissible="false" class="gl-mb-5">
    {{ errorMessage }}
  </gl-alert>
  <workload-stats v-else :stats="podStats" />
</template>
