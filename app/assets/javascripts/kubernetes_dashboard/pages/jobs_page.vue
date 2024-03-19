<script>
import { s__ } from '~/locale';
import { getAge, calculateJobStatus } from '../helpers/k8s_integration_helper';
import WorkloadLayout from '../components/workload_layout.vue';
import k8sJobsQuery from '../graphql/queries/k8s_dashboard_jobs.query.graphql';
import { STATUS_FAILED, STATUS_COMPLETED, STATUS_LABELS } from '../constants';

export default {
  components: {
    WorkloadLayout,
  },
  inject: ['configuration'],
  apollo: {
    k8sJobs: {
      query: k8sJobsQuery,
      variables() {
        return {
          configuration: this.configuration,
        };
      },
      update(data) {
        return (
          data?.k8sJobs?.map((job) => {
            return {
              name: job.metadata.name,
              namespace: job.metadata.namespace,
              status: calculateJobStatus(job),
              age: getAge(job.metadata.creationTimestamp),
              labels: job.metadata.labels,
              annotations: job.metadata.annotations,
              kind: s__('KubernetesDashboard|Job'),
              spec: job.spec,
              fullStatus: job.status,
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
      k8sJobs: [],
      errorMessage: '',
    };
  },
  computed: {
    jobsStats() {
      return [
        {
          value: this.countJobsByStatus(STATUS_COMPLETED),
          title: STATUS_LABELS[STATUS_COMPLETED],
        },
        {
          value: this.countJobsByStatus(STATUS_FAILED),
          title: STATUS_LABELS[STATUS_FAILED],
        },
      ];
    },
    loading() {
      return this.$apollo.queries.k8sJobs.loading;
    },
  },
  methods: {
    countJobsByStatus(phase) {
      const filteredJobs = this.k8sJobs.filter((item) => item.status === phase) || [];

      return filteredJobs.length;
    },
  },
};
</script>
<template>
  <workload-layout
    :loading="loading"
    :error-message="errorMessage"
    :stats="jobsStats"
    :items="k8sJobs"
  />
</template>
