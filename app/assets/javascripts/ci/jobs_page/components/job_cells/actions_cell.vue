<script>
import {
  GlButton,
  GlButtonGroup,
  GlModal,
  GlModalDirective,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import { reportToSentry } from '~/ci/utils';
import GlCountdown from '~/vue_shared/components/gl_countdown.vue';
import { visitUrl } from '~/lib/utils/url_utility';
import { confirmJobConfirmationMessage } from '~/ci/pipeline_details/graph/utils';

import {
  ACTIONS_DOWNLOAD_ARTIFACTS,
  ACTIONS_START_NOW,
  ACTIONS_UNSCHEDULE,
  ACTIONS_PLAY,
  ACTIONS_RETRY,
  ACTIONS_RUN_AGAIN,
  CANCEL,
  GENERIC_ERROR,
  JOB_SCHEDULED,
  JOB_SUCCESS,
  PLAY_JOB_CONFIRMATION_MESSAGE,
  RUN_JOB_NOW_HEADER_TITLE,
  FILE_TYPE_ARCHIVE,
} from '../../constants';
import eventHub from '../../event_hub';
import cancelJobMutation from '../../graphql/mutations/job_cancel.mutation.graphql';
import playJobMutation from '../../graphql/mutations/job_play.mutation.graphql';
import retryJobMutation from '../../graphql/mutations/job_retry.mutation.graphql';
import unscheduleJobMutation from '../../graphql/mutations/job_unschedule.mutation.graphql';

export default {
  ACTIONS_DOWNLOAD_ARTIFACTS,
  ACTIONS_START_NOW,
  ACTIONS_UNSCHEDULE,
  ACTIONS_PLAY,
  ACTIONS_RETRY,
  CANCEL,
  GENERIC_ERROR,
  PLAY_JOB_CONFIRMATION_MESSAGE,
  RUN_JOB_NOW_HEADER_TITLE,
  jobRetry: 'jobRetry',
  jobCancel: 'jobCancel',
  jobPlay: 'jobPlay',
  jobUnschedule: 'jobUnschedule',
  playJobModalId: 'play-job-modal',
  name: 'JobActionsCell',
  components: {
    GlButton,
    GlButtonGroup,
    GlCountdown,
    GlModal,
    GlSprintf,
  },
  directives: {
    GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    admin: {
      default: false,
    },
  },
  props: {
    job: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      retryingJob: false,
      cancelBtnDisabled: false,
      playManualBtnDisabled: false,
      unscheduleBtnDisabled: false,
    };
  },
  computed: {
    hasArtifacts() {
      return this.job.artifacts.nodes.find((artifact) => artifact.fileType === FILE_TYPE_ARCHIVE);
    },
    artifactDownloadPath() {
      return this.hasArtifacts.downloadPath;
    },
    canCancelJob() {
      return this.job.userPermissions?.cancelBuild;
    },
    canReadJob() {
      return this.job.userPermissions?.readBuild;
    },
    canUpdateJob() {
      return this.job.userPermissions?.updateBuild;
    },
    canReadArtifacts() {
      return this.job.userPermissions?.readJobArtifacts;
    },
    isActive() {
      return this.job.active;
    },
    manualJobPlayable() {
      return this.job.playable && !this.admin && this.job.manualJob;
    },
    isRetryable() {
      return this.job.retryable;
    },
    isScheduled() {
      return this.job.status === JOB_SCHEDULED;
    },
    scheduledAt() {
      return this.job.scheduledAt;
    },
    currentJobActionPath() {
      return this.job.detailedStatus?.action?.path;
    },
    currentJobMethod() {
      return this.job.detailedStatus?.action?.method;
    },
    shouldDisplayArtifacts() {
      return this.canReadArtifacts && this.hasArtifacts;
    },
    retryButtonTitle() {
      return this.job.status === JOB_SUCCESS ? ACTIONS_RUN_AGAIN : ACTIONS_RETRY;
    },
  },
  methods: {
    async postJobAction(name, mutation, redirect = false) {
      try {
        const {
          data: {
            [name]: { errors, job },
          },
        } = await this.$apollo.mutate({
          mutation,
          variables: { id: this.job.id },
        });
        if (errors.length > 0) {
          reportToSentry(this.$options.name, new Error(errors.join(', ')));
          this.showToastMessage();
        } else if (redirect) {
          // Retry and Play actions redirect to job detail view
          // we don't need to refetch with jobActionPerformed event
          visitUrl(job.detailedStatus.detailsPath);
        } else {
          eventHub.$emit('jobActionPerformed');
        }
      } catch (failure) {
        reportToSentry(this.$options.name, failure);
        this.showToastMessage();
      }
    },
    showToastMessage() {
      const toastProps = {
        text: this.$options.GENERIC_ERROR,
        variant: 'danger',
      };

      this.$toast.show(toastProps.text, {
        variant: toastProps.variant,
      });
    },
    cancelJob() {
      this.cancelBtnDisabled = true;

      this.postJobAction(this.$options.jobCancel, cancelJobMutation);
    },
    async retryJob() {
      if (this.job?.detailedStatus?.action?.confirmationMessage) {
        const confirmed = await confirmJobConfirmationMessage(
          this.job.name,
          this.job.detailedStatus.action.confirmationMessage,
        );

        if (!confirmed) {
          return;
        }
      }

      this.retryingJob = true;

      this.postJobAction(this.$options.jobRetry, retryJobMutation, true);
    },
    async playJob() {
      if (this.job?.detailedStatus?.action?.confirmationMessage) {
        const confirmed = await confirmJobConfirmationMessage(
          this.job.name,
          this.job.detailedStatus.action.confirmationMessage,
        );

        if (!confirmed) {
          return;
        }
      }

      this.playManualBtnDisabled = true;

      this.postJobAction(this.$options.jobPlay, playJobMutation, true);
    },
    unscheduleJob() {
      this.unscheduleBtnDisabled = true;

      this.postJobAction(this.$options.jobUnschedule, unscheduleJobMutation);
    },
  },
};
</script>

<template>
  <gl-button-group>
    <template v-if="canReadJob && canUpdateJob">
      <gl-button
        v-if="isActive && canCancelJob"
        v-gl-tooltip
        icon="cancel"
        :title="$options.CANCEL"
        :aria-label="$options.CANCEL"
        :disabled="cancelBtnDisabled"
        data-testid="cancel-button"
        @click="cancelJob()"
      />
      <template v-else-if="isScheduled">
        <gl-button icon="planning" disabled data-testid="countdown">
          <gl-countdown :end-date-string="scheduledAt" />
        </gl-button>
        <gl-button
          v-gl-modal-directive="$options.playJobModalId"
          v-gl-tooltip
          icon="play"
          :title="$options.ACTIONS_START_NOW"
          :aria-label="$options.ACTIONS_START_NOW"
          data-testid="play-scheduled"
        />
        <gl-modal
          :modal-id="$options.playJobModalId"
          :title="$options.RUN_JOB_NOW_HEADER_TITLE"
          @primary="playJob()"
        >
          <gl-sprintf :message="$options.PLAY_JOB_CONFIRMATION_MESSAGE">
            <template #job_name>{{ job.name }}</template>
          </gl-sprintf>
        </gl-modal>
        <gl-button
          v-gl-tooltip
          icon="time-out"
          :title="$options.ACTIONS_UNSCHEDULE"
          :aria-label="$options.ACTIONS_UNSCHEDULE"
          :disabled="unscheduleBtnDisabled"
          data-testid="unschedule"
          @click="unscheduleJob()"
        />
      </template>
      <template v-else>
        <!--Note: This is the manual job play button -->
        <gl-button
          v-if="manualJobPlayable"
          v-gl-tooltip
          icon="play"
          :title="$options.ACTIONS_PLAY"
          :aria-label="$options.ACTIONS_PLAY"
          :disabled="playManualBtnDisabled"
          data-testid="play"
          @click="playJob()"
        />
        <gl-button
          v-else-if="isRetryable"
          v-gl-tooltip
          icon="retry"
          :title="retryButtonTitle"
          :aria-label="retryButtonTitle"
          :method="currentJobMethod"
          :loading="retryingJob"
          data-testid="retry"
          @click="retryJob()"
        />
      </template>
    </template>
    <gl-button
      v-if="shouldDisplayArtifacts"
      v-gl-tooltip
      icon="download"
      :title="$options.ACTIONS_DOWNLOAD_ARTIFACTS"
      :aria-label="$options.ACTIONS_DOWNLOAD_ARTIFACTS"
      :href="artifactDownloadPath"
      rel="nofollow"
      download
      data-testid="download-artifacts"
    />
  </gl-button-group>
</template>
