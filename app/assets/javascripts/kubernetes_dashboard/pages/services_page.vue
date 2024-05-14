<script>
import { s__ } from '~/locale';
import { getAge, generateServicePortsString } from '../helpers/k8s_integration_helper';
import { SERVICES_TABLE_FIELDS } from '../constants';
import WorkloadLayout from '../components/workload_layout.vue';
import k8sServicesQuery from '../graphql/queries/k8s_dashboard_services.query.graphql';

export default {
  components: {
    WorkloadLayout,
  },
  inject: ['configuration'],
  apollo: {
    k8sServices: {
      query: k8sServicesQuery,
      variables() {
        return {
          configuration: this.configuration,
        };
      },
      update(data) {
        return (
          data?.k8sDashboardServices?.map((service) => {
            return {
              name: service.metadata.name,
              namespace: service.metadata.namespace,
              type: service.spec.type,
              clusterIP: service.spec.clusterIP || '-',
              externalIP: service.spec.externalIP || '-',
              ports: generateServicePortsString(service.spec.ports),
              age: getAge(service.metadata.creationTimestamp),
              labels: service.metadata.labels,
              annotations: service.metadata.annotations,
              kind: s__('KubernetesDashboard|Service'),
              spec: service.spec,
              fullStatus: service.status,
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
      k8sServices: [],
      errorMessage: '',
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.k8sServices.loading;
    },
    servicesStats() {
      return [];
    },
  },
  SERVICES_TABLE_FIELDS,
};
</script>
<template>
  <workload-layout
    :loading="loading"
    :error-message="errorMessage"
    :stats="servicesStats"
    :items="k8sServices"
    :fields="$options.SERVICES_TABLE_FIELDS"
  />
</template>
