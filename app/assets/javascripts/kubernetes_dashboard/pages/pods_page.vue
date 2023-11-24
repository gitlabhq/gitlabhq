<script>
import { getAge } from '../helpers/k8s_integration_helper';
import WorkloadLayout from '../components/workload_layout.vue';
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
    WorkloadLayout,
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
        return (
          data?.k8sPods?.map((pod) => {
            return {
              name: pod.metadata?.name,
              namespace: pod.metadata?.namespace,
              status: pod.status.phase,
              age: getAge(pod.metadata?.creationTimestamp),
            };
          }) || []
        );
      },
      error(err) {
        this.errorMessage = err?.message;
      },
    },
  },
  data() {
    return {
      k8sPods: [],
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
      const filteredPods = this.k8sPods?.filter((item) => item.status === phase) || [];

      return filteredPods.length;
    },
  },
};
</script>
<template>
  <workload-layout
    :loading="loading"
    :error-message="errorMessage"
    :stats="podStats"
    :items="k8sPods"
  />
</template>
