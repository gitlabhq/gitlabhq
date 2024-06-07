<script>
import { s__ } from '~/locale';
import { getAge, calculateDeploymentStatus } from '../helpers/k8s_integration_helper';
import WorkloadLayout from '../components/workload_layout.vue';
import k8sDashboardDeploymentsQuery from '../graphql/queries/k8s_dashboard_deployments.query.graphql';
import { STATUS_FAILED, STATUS_READY, STATUS_PENDING, STATUS_LABELS } from '../constants';

export default {
  components: {
    WorkloadLayout,
  },
  inject: ['configuration'],
  apollo: {
    k8sDashboardDeployments: {
      query: k8sDashboardDeploymentsQuery,
      variables() {
        return {
          configuration: this.configuration,
        };
      },
      update(data) {
        return (
          data?.k8sDashboardDeployments?.map((deployment) => {
            return {
              name: deployment.metadata.name,
              namespace: deployment.metadata.namespace,
              status: calculateDeploymentStatus(deployment),
              age: getAge(deployment.metadata.creationTimestamp),
              labels: deployment.metadata.labels,
              annotations: deployment.metadata.annotations,
              kind: s__('KubernetesDashboard|Deployment'),
              spec: deployment.spec,
              fullStatus: deployment.status,
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
      k8sDashboardDeployments: [],
      errorMessage: '',
    };
  },
  computed: {
    deploymentsStats() {
      return [
        {
          value: this.countDeploymentsByStatus(STATUS_READY),
          title: STATUS_LABELS[STATUS_READY],
        },
        {
          value: this.countDeploymentsByStatus(STATUS_FAILED),
          title: STATUS_LABELS[STATUS_FAILED],
        },
        {
          value: this.countDeploymentsByStatus(STATUS_PENDING),
          title: STATUS_LABELS[STATUS_PENDING],
        },
      ];
    },
    loading() {
      return this.$apollo.queries.k8sDashboardDeployments.loading;
    },
  },
  methods: {
    countDeploymentsByStatus(phase) {
      const filteredDeployments =
        this.k8sDashboardDeployments.filter((item) => item.status === phase) || [];

      return filteredDeployments.length;
    },
  },
};
</script>
<template>
  <workload-layout
    :loading="loading"
    :error-message="errorMessage"
    :stats="deploymentsStats"
    :items="k8sDashboardDeployments"
  />
</template>
