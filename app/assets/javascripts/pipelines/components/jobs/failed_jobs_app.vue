<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import GetFailedJobsQuery from '../../graphql/queries/get_failed_jobs.query.graphql';
import FailedJobsTable from './failed_jobs_table.vue';

export default {
  components: {
    GlLoadingIcon,
    FailedJobsTable,
  },
  inject: {
    projectPath: {
      default: '',
    },
    pipelineIid: {
      default: '',
    },
  },
  apollo: {
    failedJobs: {
      query: GetFailedJobsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          pipelineIid: this.pipelineIid,
        };
      },
      update({ project }) {
        const jobNodes = project?.pipeline?.jobs?.nodes || [];

        return jobNodes.map((job) => {
          return {
            ...job,
            // this field is needed for the slot row-details
            // on the failed_jobs_table.vue component
            _showDetails: true,
          };
        });
      },
      error() {
        createAlert({ message: s__('Jobs|There was a problem fetching the failed jobs.') });
      },
    },
  },
  data() {
    return {
      failedJobs: [],
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.failedJobs.loading;
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="loading" size="lg" class="gl-mt-4" />
    <failed-jobs-table v-else :failed-jobs="failedJobs" />
  </div>
</template>
