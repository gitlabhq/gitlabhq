<script>
import { GlButton, GlLink, GlTooltip, GlTooltipDirective } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__, sprintf } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { BRIDGE_KIND, BUILD_KIND } from '~/ci/pipeline_details/graph/constants';
import RetryMrFailedJobMutation from '~/ci/merge_requests/graphql/mutations/retry_mr_failed_job.mutation.graphql';
import RootCauseAnalysisButton from 'ee_else_ce/ci/job_details/components/root_cause_analysis_button.vue';

export default {
  components: {
    CiIcon,
    GlButton,
    GlLink,
    GlTooltip,
    RootCauseAnalysisButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  props: {
    job: {
      type: Object,
      required: true,
    },
    canTroubleshootJob: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isLoadingAction: false,
    };
  },
  computed: {
    canRetryJob() {
      return this.job.retryable && this.job.userPermissions.updateBuild && !this.isBridgeJob;
    },
    detailedStatus() {
      return this.job?.detailedStatus;
    },
    detailsPath() {
      return this.detailedStatus?.detailsPath;
    },
    statusGroup() {
      return this.detailedStatus?.group;
    },
    isBridgeJob() {
      return this.job.kind === BRIDGE_KIND;
    },
    parsedJobId() {
      return getIdFromGraphQLId(this.job.id);
    },
    tooltipErrorText() {
      return this.isBridgeJob
        ? this.$options.i18n.cannotRetryTrigger
        : this.$options.i18n.cannotRetry;
    },
    tooltipText() {
      return sprintf(this.$options.i18n.jobActionTooltipText, { jobName: this.job.name });
    },
    isBuildJob() {
      return this.job.kind === BUILD_KIND;
    },
  },
  methods: {
    async retryJob() {
      try {
        this.isLoadingAction = true;

        const {
          data: {
            jobRetry: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: RetryMrFailedJobMutation,
          variables: { id: this.job.id },
        });

        if (errors.length > 0) {
          throw new Error(errors[0]);
        }

        this.$emit('job-retried', this.job.name);
      } catch (error) {
        createAlert({ message: error?.message || this.$options.i18n.retryError });
      } finally {
        this.isLoadingAction = false;
      }
    },
  },
  i18n: {
    cannotReadBuild: s__("Job|You do not have permission to read this job's log."),
    cannotRetry: s__('Job|You do not have permission to run this job again.'),
    cannotRetryTrigger: s__('Job|You cannot rerun trigger jobs from this list.'),
    jobActionTooltipText: s__('Pipelines|Retry %{jobName} Job'),
    retry: __('Run again'),
    retryError: __('There was an error while running this job again'),
  },
};
</script>
<template>
  <div class="container-fluid gl-my-1 gl-grid-rows-auto">
    <div
      class="row gl-my-3 gl-flex gl-flex-wrap gl-items-center gl-gap-y-4"
      data-testid="widget-row"
    >
      <div class="align-items-center col-4 gl-flex gl-text-default">
        <ci-icon :status="job.detailedStatus" />
        <gl-link
          class="gl-ml-2 !gl-text-default !gl-no-underline"
          :href="detailsPath"
          data-testid="job-name-link"
          >{{ job.name }}</gl-link
        >
      </div>
      <div class="col-2 gl-flex gl-items-center" data-testid="job-stage-name">
        {{ job.stage.name }}
      </div>
      <div class="col-2 gl-flex gl-items-center">
        <gl-link :href="detailsPath" data-testid="job-id-link">#{{ parsedJobId }}</gl-link>
      </div>
      <gl-tooltip v-if="!canRetryJob" :target="() => $refs.retryBtn" placement="top">
        {{ tooltipErrorText }}
      </gl-tooltip>
      <div class="col-4 gl-flex gl-max-w-full gl-flex-grow gl-justify-end gl-gap-3">
        <root-cause-analysis-button
          :job-gid="job.id"
          :job-status-group="statusGroup"
          :can-troubleshoot-job="canTroubleshootJob"
          :is-build="isBuildJob"
        />

        <span ref="retryBtn">
          <gl-button
            v-gl-tooltip
            :disabled="!canRetryJob"
            icon="retry"
            category="secondary"
            :loading="isLoadingAction"
            :title="$options.i18n.retry"
            :aria-label="$options.i18n.retry"
            data-testid="retry-button"
            @click.stop="retryJob"
          />
        </span>
      </div>
    </div>
  </div>
</template>
