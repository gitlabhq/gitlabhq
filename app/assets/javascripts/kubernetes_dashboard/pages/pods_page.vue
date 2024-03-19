<script>
import { s__ } from '~/locale';
import { getAge } from '../helpers/k8s_integration_helper';
import WorkloadLayout from '../components/workload_layout.vue';
import k8sPodsQuery from '../graphql/queries/k8s_dashboard_pods.query.graphql';
import {
  STATUS_RUNNING,
  STATUS_PENDING,
  STATUS_SUCCEEDED,
  STATUS_FAILED,
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
          data?.k8sDashboardPods?.map((pod) => {
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
