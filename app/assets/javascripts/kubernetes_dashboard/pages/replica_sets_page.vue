<script>
import { s__ } from '~/locale';
import { getAge, calculateStatefulSetStatus } from '../helpers/k8s_integration_helper';
import WorkloadLayout from '../components/workload_layout.vue';
import k8sReplicaSetsQuery from '../graphql/queries/k8s_dashboard_replica_sets.query.graphql';
import { STATUS_FAILED, STATUS_READY, STATUS_LABELS } from '../constants';

export default {
  components: {
    WorkloadLayout,
  },
  inject: ['configuration'],
  apollo: {
    k8sReplicaSets: {
      query: k8sReplicaSetsQuery,
      variables() {
        return {
          configuration: this.configuration,
        };
      },
      update(data) {
        return (
          data?.k8sReplicaSets?.map((replicaSet) => {
            return {
              name: replicaSet.metadata.name,
              namespace: replicaSet.metadata.namespace,
              status: calculateStatefulSetStatus(replicaSet),
              age: getAge(replicaSet.metadata.creationTimestamp),
              labels: replicaSet.metadata.labels,
              annotations: replicaSet.metadata.annotations,
              kind: s__('KubernetesDashboard|ReplicaSet'),
              spec: replicaSet.spec,
              fullStatus: replicaSet.status,
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
      k8sReplicaSets: [],
      errorMessage: '',
    };
  },
  computed: {
    replicaSetsStats() {
      return [
        {
          value: this.countReplicaSetsByStatus(STATUS_READY),
          title: STATUS_LABELS[STATUS_READY],
        },
        {
          value: this.countReplicaSetsByStatus(STATUS_FAILED),
          title: STATUS_LABELS[STATUS_FAILED],
        },
      ];
    },
    loading() {
      return this.$apollo.queries.k8sReplicaSets.loading;
    },
  },
  methods: {
    countReplicaSetsByStatus(phase) {
      const filteredReplicaSets = this.k8sReplicaSets.filter((item) => item.status === phase) || [];

      return filteredReplicaSets.length;
    },
  },
};
</script>
<template>
  <workload-layout
    :loading="loading"
    :error-message="errorMessage"
    :stats="replicaSetsStats"
    :items="k8sReplicaSets"
  />
</template>
