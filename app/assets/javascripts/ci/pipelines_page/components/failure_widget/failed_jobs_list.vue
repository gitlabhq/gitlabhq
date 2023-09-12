<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__, sprintf } from '~/locale';
import { getQueryHeaders } from '~/ci/pipeline_details/graph/utils';
import { graphqlEtagPipelinePath } from '~/ci/pipeline_details/utils';
import getPipelineFailedJobs from '~/ci/pipelines_page/graphql/queries/get_pipeline_failed_jobs.query.graphql';
import { sortJobsByStatus } from './utils';
import FailedJobDetails from './failed_job_details.vue';

const POLL_INTERVAL = 10000;

const JOB_ID_HEADER = __('ID');
const JOB_NAME_HEADER = __('Name');
const STAGE_HEADER = __('Stage');

export default {
  components: {
    GlLoadingIcon,
    FailedJobDetails,
  },
  inject: ['graphqlPath'],
  props: {
    failedJobsCount: {
      required: true,
      type: Number,
    },
    isPipelineActive: {
      required: true,
      type: Boolean,
    },
    pipelineIid: {
      type: Number,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      failedJobs: [],
      isActive: false,
      isLoadingMore: false,
    };
  },
  apollo: {
    failedJobs: {
      context() {
        return getQueryHeaders(this.graphqlResourceEtag);
      },
      query: getPipelineFailedJobs,
      pollInterval: POLL_INTERVAL,
      variables() {
        return {
          fullPath: this.projectPath,
          pipelineIid: this.pipelineIid,
        };
      },
      update(data) {
        const jobs = data?.project?.pipeline?.jobs?.nodes || [];
        return sortJobsByStatus(jobs);
      },
      result({ data }) {
        const pipeline = data?.project?.pipeline;

        if (pipeline?.jobs?.count) {
          this.$emit('failed-jobs-count', pipeline.jobs.count);
          this.isActive = pipeline.active;
        }
      },
      error(e) {
        createAlert({ message: e?.message || this.$options.i18n.fetchError, variant: 'danger' });
      },
    },
  },
  computed: {
    graphqlResourceEtag() {
      return graphqlEtagPipelinePath(this.graphqlPath, this.pipelineIid);
    },
    hasFailedJobs() {
      return this.failedJobs.length > 0;
    },
    isInitialLoading() {
      return this.isLoading && !this.isLoadingMore;
    },
    isLoading() {
      return this.$apollo.queries.failedJobs.loading;
    },
  },
  watch: {
    isPipelineActive(flag) {
      // Turn polling on and off based on REST actions
      // By refetching jobs, we will get the graphql `active`
      // field to update properly and cascade the polling changes
      this.refetchJobs();
      this.handlePolling(flag);
    },
    isActive(flag) {
      this.handlePolling(flag);
    },
    failedJobsCount(count) {
      // If the REST data is updated first, we force a refetch
      // to keep them in sync
      if (this.failedJobs.length !== count) {
        this.$apollo.queries.failedJobs.refetch();
      }
    },
  },
  mounted() {
    if (!this.isActive && !this.isPipelineActive) {
      this.handlePolling(false);
    }
  },
  methods: {
    handlePolling(isActive) {
      // If the pipeline status has changed and the widget is not expanded,
      // We start polling.
      if (isActive) {
        this.$apollo.queries.failedJobs.startPolling(POLL_INTERVAL);
      } else {
        this.$apollo.queries.failedJobs.stopPolling();
      }
    },
    async retryJob(jobName) {
      await this.refetchJobs();

      this.$toast.show(sprintf(this.$options.i18n.retriedJobsSuccess, { jobName }));
    },
    async refetchJobs() {
      this.isLoadingMore = true;

      try {
        await this.$apollo.queries.failedJobs.refetch();
      } catch {
        createAlert(this.$options.i18n.fetchError);
      } finally {
        this.isLoadingMore = false;
      }
    },
  },
  columns: [
    { text: JOB_NAME_HEADER, class: 'col-6' },
    { text: STAGE_HEADER, class: 'col-2' },
    { text: JOB_ID_HEADER, class: 'col-2' },
  ],
  i18n: {
    fetchError: __('There was a problem fetching failed jobs'),
    noFailedJobs: s__('Pipeline|No failed jobs in this pipeline 🎉'),
    retriedJobsSuccess: __('%{jobName} job is being retried'),
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isInitialLoading" class="gl-p-4" />
    <div v-else-if="!hasFailedJobs" class="gl-p-4">{{ $options.i18n.noFailedJobs }}</div>
    <div v-else class="container-fluid gl-grid-tpl-rows-auto">
      <div class="row gl-my-4 gl-text-gray-900">
        <div
          v-for="col in $options.columns"
          :key="col.text"
          class="gl-font-weight-bold gl-text-left"
          :class="col.class"
          data-testid="header"
        >
          {{ col.text }}
        </div>
      </div>
    </div>
    <failed-job-details
      v-for="job in failedJobs"
      :key="job.id"
      :job="job"
      @job-retried="retryJob"
    />
  </div>
</template>
