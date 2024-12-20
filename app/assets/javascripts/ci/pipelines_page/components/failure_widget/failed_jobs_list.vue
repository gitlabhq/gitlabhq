<script>
import { GlAlert, GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__, sprintf } from '~/locale';
import { getQueryHeaders } from '~/ci/pipeline_details/graph/utils';
import { graphqlEtagPipelinePath } from '~/ci/pipeline_details/utils';
import { toggleQueryPollingByVisibility } from '~/graphql_shared/utils';
import getPipelineFailedJobs from '~/ci/pipelines_page/graphql/queries/get_pipeline_failed_jobs.query.graphql';
import { sortJobsByStatus } from './utils';
import FailedJobDetails from './failed_job_details.vue';
import { POLL_INTERVAL } from './constants';

const JOB_ID_HEADER = __('ID');
const JOB_NAME_HEADER = __('Name');
const STAGE_HEADER = __('Stage');

export default {
  components: {
    GlAlert,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
    FailedJobDetails,
  },
  inject: ['graphqlPath'],
  props: {
    isMaximumJobLimitReached: {
      required: true,
      type: Boolean,
    },
    pipelineIid: {
      type: Number,
      required: true,
    },
    pipelinePath: {
      required: true,
      type: String,
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      failedJobs: [],
      isLoadingMore: false,
      canTroubleshootJob: false,
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
        this.canTroubleshootJob = pipeline?.troubleshootJobWithAi || false;
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
    isInitialLoading() {
      return this.isLoading && !this.isLoadingMore;
    },
    isLoading() {
      return this.$apollo.queries.failedJobs.loading;
    },
  },
  mounted() {
    toggleQueryPollingByVisibility(this.$apollo.queries.failedJobs, POLL_INTERVAL);
  },
  methods: {
    async retryJob(jobName) {
      await this.refetchJobs();

      this.$emit('job-retried');

      this.$toast.show(sprintf(this.$options.i18n.retriedJobsSuccess, { jobName }));
    },
    async refetchJobs() {
      this.isLoadingMore = true;

      try {
        await this.$apollo.queries.failedJobs.refetch();
      } catch {
        createAlert({ message: this.$options.i18n.fetchError });
      } finally {
        this.isLoadingMore = false;
      }
    },
  },
  columns: [
    { text: JOB_NAME_HEADER, class: 'col-4' },
    { text: STAGE_HEADER, class: 'col-2' },
    { text: JOB_ID_HEADER, class: 'col-2' },
  ],
  i18n: {
    maximumJobLimitAlert: {
      title: s__('Pipelines|Maximum list size reached'),
      message: s__(
        `Pipelines| The list can only display 100 jobs. To view all jobs, %{linkStart}go to this pipeline's details page.%{linkEnd}`,
      ),
    },
    fetchError: __('There was a problem fetching failed jobs'),
    retriedJobsSuccess: __('%{jobName} job is being retried'),
  },
};
</script>

<template>
  <div class="gl-mb-4">
    <gl-loading-icon v-if="isInitialLoading" class="gl-p-4" />
    <div v-else class="container-fluid gl-grid-rows-auto">
      <gl-alert
        v-if="isMaximumJobLimitReached"
        :title="$options.i18n.maximumJobLimitAlert.title"
        variant="warning"
        class="gl-mt-4"
      >
        <gl-sprintf :message="$options.i18n.maximumJobLimitAlert.message">
          <template #link="{ content }">
            <gl-link class="!gl-no-underline" :href="pipelinePath" target="_blank">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </gl-alert>
      <div class="row gl-my-4 gl-text-default">
        <div
          v-for="col in $options.columns"
          :key="col.text"
          class="gl-flex gl-font-bold"
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
      :can-troubleshoot-job="canTroubleshootJob"
      @job-retried="retryJob"
    />
  </div>
</template>
