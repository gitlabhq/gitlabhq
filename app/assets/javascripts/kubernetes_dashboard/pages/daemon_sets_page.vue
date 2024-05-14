<script>
import { s__ } from '~/locale';
import { getAge, calculateDaemonSetStatus } from '../helpers/k8s_integration_helper';
import WorkloadLayout from '../components/workload_layout.vue';
import k8sDaemonSetsQuery from '../graphql/queries/k8s_dashboard_daemon_sets.query.graphql';
import { STATUS_FAILED, STATUS_READY, STATUS_LABELS } from '../constants';

export default {
  components: {
    WorkloadLayout,
  },
  inject: ['configuration'],
  apollo: {
    k8sDaemonSets: {
      query: k8sDaemonSetsQuery,
      variables() {
        return {
          configuration: this.configuration,
        };
      },
      update(data) {
        return (
          data?.k8sDaemonSets?.map((daemonSet) => {
            return {
              name: daemonSet.metadata.name,
              namespace: daemonSet.metadata.namespace,
              status: calculateDaemonSetStatus(daemonSet),
              age: getAge(daemonSet.metadata.creationTimestamp),
              labels: daemonSet.metadata.labels,
              annotations: daemonSet.metadata.annotations,
              kind: s__('KubernetesDashboard|DaemonSet'),
              spec: daemonSet.spec,
              fullStatus: daemonSet.status,
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
      k8sDaemonSets: [],
      errorMessage: '',
    };
  },
  computed: {
    daemonSetsStats() {
      return [
        {
          value: this.countDaemonSetsByStatus(STATUS_READY),
          title: STATUS_LABELS[STATUS_READY],
        },
        {
          value: this.countDaemonSetsByStatus(STATUS_FAILED),
          title: STATUS_LABELS[STATUS_FAILED],
        },
      ];
    },
    loading() {
      return this.$apollo.queries.k8sDaemonSets.loading;
    },
  },
  methods: {
    countDaemonSetsByStatus(status) {
      const filteredDaemonSets = this.k8sDaemonSets.filter((item) => item.status === status) || [];

      return filteredDaemonSets.length;
    },
  },
};
</script>
<template>
  <workload-layout
    :loading="loading"
    :error-message="errorMessage"
    :stats="daemonSetsStats"
    :items="k8sDaemonSets"
  />
</template>
