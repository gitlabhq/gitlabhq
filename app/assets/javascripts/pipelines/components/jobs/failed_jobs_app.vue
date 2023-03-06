<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import GetFailedJobsQuery from '../../graphql/queries/get_failed_jobs.query.graphql';
import { prepareFailedJobs } from './utils';
import FailedJobsTable from './failed_jobs_table.vue';

export default {
  components: {
    GlLoadingIcon,
    FailedJobsTable,
  },
  inject: {
    fullPath: {
      default: '',
    },
    pipelineIid: {
      default: '',
    },
  },
  props: {
    failedJobsSummary: {
      type: Array,
      required: true,
    },
  },
  apollo: {
    failedJobs: {
      query: GetFailedJobsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          pipelineIid: this.pipelineIid,
        };
      },
      update({ project }) {
        if (project?.pipeline?.jobs?.nodes) {
          return project.pipeline.jobs.nodes.map((job) => {
            return { normalizedId: getIdFromGraphQLId(job.id), ...job };
          });
        }
        return [];
      },
      result() {
        this.preparedFailedJobs = prepareFailedJobs(this.failedJobs, this.failedJobsSummary);
      },
      error() {
        createAlert({ message: s__('Jobs|There was a problem fetching the failed jobs.') });
      },
    },
  },
  data() {
    return {
      failedJobs: [],
      preparedFailedJobs: [],
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
    <failed-jobs-table v-else :failed-jobs="preparedFailedJobs" />
  </div>
</template>
