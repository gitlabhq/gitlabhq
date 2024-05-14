<script>
import { s__ } from '~/locale';
import { getAge, calculateStatefulSetStatus } from '../helpers/k8s_integration_helper';
import WorkloadLayout from '../components/workload_layout.vue';
import k8sStatefulSetsQuery from '../graphql/queries/k8s_dashboard_stateful_sets.query.graphql';
import { STATUS_FAILED, STATUS_READY, STATUS_LABELS } from '../constants';

export default {
  components: {
    WorkloadLayout,
  },
  inject: ['configuration'],
  apollo: {
    k8sStatefulSets: {
      query: k8sStatefulSetsQuery,
      variables() {
        return {
          configuration: this.configuration,
        };
      },
      update(data) {
        return (
          data?.k8sStatefulSets?.map((statefulSet) => {
            return {
              name: statefulSet.metadata.name,
              namespace: statefulSet.metadata.namespace,
              status: calculateStatefulSetStatus(statefulSet),
              age: getAge(statefulSet.metadata.creationTimestamp),
              labels: statefulSet.metadata.labels,
              annotations: statefulSet.metadata.annotations,
              kind: s__('KubernetesDashboard|StatefulSet'),
              spec: statefulSet.spec,
              fullStatus: statefulSet.status,
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
      k8sStatefulSets: [],
      errorMessage: '',
    };
  },
  computed: {
    statefulSetsStats() {
      return [
        {
          value: this.countStatefulSetsByStatus(STATUS_READY),
          title: STATUS_LABELS[STATUS_READY],
        },
        {
          value: this.countStatefulSetsByStatus(STATUS_FAILED),
          title: STATUS_LABELS[STATUS_FAILED],
        },
      ];
    },
    loading() {
      return this.$apollo.queries.k8sStatefulSets.loading;
    },
  },
  methods: {
    countStatefulSetsByStatus(phase) {
      const filteredStatefulSets =
        this.k8sStatefulSets.filter((item) => item.status === phase) || [];

      return filteredStatefulSets.length;
    },
  },
};
</script>
<template>
  <workload-layout
    :loading="loading"
    :error-message="errorMessage"
    :stats="statefulSetsStats"
    :items="k8sStatefulSets"
  />
</template>
