<script>
import { s__ } from '~/locale';
import { getAge, calculateCronJobStatus } from '../helpers/k8s_integration_helper';
import WorkloadLayout from '../components/workload_layout.vue';
import k8sCronJobsQuery from '../graphql/queries/k8s_dashboard_cron_jobs.query.graphql';
import { STATUS_FAILED, STATUS_READY, STATUS_SUSPENDED, STATUS_LABELS } from '../constants';

export default {
  components: {
    WorkloadLayout,
  },
  inject: ['configuration'],
  apollo: {
    k8sCronJobs: {
      query: k8sCronJobsQuery,
      variables() {
        return {
          configuration: this.configuration,
        };
      },
      update(data) {
        return (
          data?.k8sCronJobs?.map((job) => {
            return {
              name: job.metadata.name,
              namespace: job.metadata.namespace,
              status: calculateCronJobStatus(job),
              age: getAge(job.metadata.creationTimestamp),
              labels: job.metadata.labels,
              annotations: job.metadata.annotations,
              kind: s__('KubernetesDashboard|CronJob'),
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
      k8sCronJobs: [],
      errorMessage: '',
    };
  },
  computed: {
    cronJobsStats() {
      return [
        {
          value: this.countJobsByStatus(STATUS_READY),
          title: STATUS_LABELS[STATUS_READY],
        },
        {
          value: this.countJobsByStatus(STATUS_FAILED),
          title: STATUS_LABELS[STATUS_FAILED],
        },
        {
          value: this.countJobsByStatus(STATUS_SUSPENDED),
          title: STATUS_LABELS[STATUS_SUSPENDED],
        },
      ];
    },
    loading() {
      return this.$apollo.queries.k8sCronJobs.loading;
    },
  },
  methods: {
    countJobsByStatus(phase) {
      const filteredJobs = this.k8sCronJobs.filter((item) => item.status === phase) || [];

      return filteredJobs.length;
    },
  },
};
</script>
<template>
  <workload-layout
    :loading="loading"
    :error-message="errorMessage"
    :stats="cronJobsStats"
    :items="k8sCronJobs"
  />
</template>
