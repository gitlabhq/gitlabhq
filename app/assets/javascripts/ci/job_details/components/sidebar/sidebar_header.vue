<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { TYPENAME_COMMIT_STATUS } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { __, s__ } from '~/locale';
import { JOB_GRAPHQL_ERRORS, forwardDeploymentFailureModalId, PASSED_STATUS } from '~/ci/constants';
import GetJob from '../../graphql/queries/get_job.query.graphql';
import JobSidebarRetryButton from './job_sidebar_retry_button.vue';

export default {
  name: 'SidebarHeader',
  i18n: {
    cancelJobButtonLabel: s__('Job|Cancel'),
    debug: __('Debug'),
    eraseLogButtonLabel: s__('Job|Erase job log and artifacts'),
    eraseLogConfirmText: s__('Job|Are you sure you want to erase this job log and artifacts?'),
    retryJobLabel: s__('Job|Retry'),
    runAgainJobButtonLabel: s__('Job|Run again'),
    forceCancelJobButtonLabel: s__('Job|Force cancel'),
    forceCancelJobButtonTooltip: s__('Job|Force cancel a job stuck in canceling state'),
    forceCancelJobConfirmText: s__(
      'Job|Are you sure you want to force cancel this job? This will immediately mark the job as canceled, even if the job is still running.',
    ),
  },
  forwardDeploymentFailureModalId,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
    JobSidebarRetryButton,
  },
  inject: ['projectPath'],
  apollo: {
    job: {
      query: GetJob,
      variables() {
        return {
          fullPath: this.projectPath,
          id: convertToGraphQLId(TYPENAME_COMMIT_STATUS, this.jobId),
        };
      },
      update(data) {
        const { name, manualJob, inputsSpec } = data?.project?.job || {};
        return {
          name,
          manualJob,
          inputsSpec,
        };
      },
      error() {
        createAlert({ message: JOB_GRAPHQL_ERRORS.jobQueryErrorText });
      },
    },
  },
  props: {
    jobId: {
      type: Number,
      required: true,
    },
    restJob: {
      type: Object,
      required: true,
      default: () => ({}),
    },
  },
  emits: ['update-variables'],
  data() {
    return {
      job: {},
    };
  },
  computed: {
    buttonTitle() {
      return this.restJob.status?.text === PASSED_STATUS
        ? this.$options.i18n.runAgainJobButtonLabel
        : this.$options.i18n.retryJobLabel;
    },
    canShowJobRetryButton() {
      return this.restJob.retry_path && !this.$apollo.queries.job.loading;
    },
    jobConfirmationMessage() {
      return this.restJob.status.action.confirmation_message;
    },
    isManualJob() {
      return Boolean(this.job?.manualJob);
    },
    hasInputs() {
      return this.job?.inputsSpec?.length > 0;
    },
    retryButtonVariant() {
      return this.restJob.status && this.restJob.recoverable ? 'confirm' : 'default';
    },
    jobHasPath() {
      return Boolean(
        this.restJob.erase_path ||
        this.restJob.terminal_path ||
        this.restJob.retry_path ||
        this.restJob.cancel_path ||
        this.restJob.force_cancel_path,
      );
    },
  },
};
</script>

<template>
  <div v-if="jobHasPath" class="gl-flex gl-gap-3">
    <job-sidebar-retry-button
      v-if="canShowJobRetryButton"
      v-gl-tooltip.bottom
      :retry-button-title="buttonTitle"
      :is-manual-job="isManualJob"
      :has-inputs="hasInputs"
      :href="restJob.retry_path"
      :confirmation-message="jobConfirmationMessage"
      :job-name="restJob.name"
      :modal-id="$options.forwardDeploymentFailureModalId"
      :variant="retryButtonVariant"
      data-testid="retry-button"
      @update-variables-clicked="$emit('update-variables')"
    />
    <gl-button
      v-if="restJob.cancel_path"
      v-gl-tooltip.bottom
      :title="$options.i18n.cancelJobButtonLabel"
      :aria-label="$options.i18n.cancelJobButtonLabel"
      :href="restJob.cancel_path"
      variant="danger"
      data-method="post"
      data-testid="cancel-button"
      rel="nofollow"
    >
      {{ $options.i18n.cancelJobButtonLabel }}
    </gl-button>
    <gl-button
      v-if="restJob.force_cancel_path"
      v-gl-tooltip.bottom
      :title="$options.i18n.forceCancelJobButtonTooltip"
      :aria-label="$options.i18n.forceCancelJobButtonLabel"
      :href="restJob.force_cancel_path"
      :data-confirm="$options.i18n.forceCancelJobConfirmText"
      data-confirm-btn-variant="danger"
      variant="danger"
      data-method="post"
      data-testid="force-cancel-button"
      rel="nofollow"
    >
      {{ $options.i18n.forceCancelJobButtonLabel }}
    </gl-button>
    <gl-button
      v-if="restJob.erase_path"
      v-gl-tooltip.bottom
      :title="$options.i18n.eraseLogButtonLabel"
      :aria-label="$options.i18n.eraseLogButtonLabel"
      :href="restJob.erase_path"
      :data-confirm="$options.i18n.eraseLogConfirmText"
      data-testid="job-log-erase-link"
      data-confirm-btn-variant="danger"
      data-method="post"
      icon="remove"
      category="tertiary"
      size="small"
      class="btn-icon gl-self-center"
    />
    <gl-button
      v-if="restJob.terminal_path"
      v-gl-tooltip.bottom
      :href="restJob.terminal_path"
      :title="$options.i18n.debug"
      :aria-label="$options.i18n.debug"
      target="_blank"
      icon="external-link"
      category="tertiary"
      size="small"
      class="btn-icon gl-self-center"
      data-testid="terminal-link"
    />
  </div>
</template>
