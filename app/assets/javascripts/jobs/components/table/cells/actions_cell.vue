<script>
import { GlButton, GlButtonGroup, GlModal, GlModalDirective, GlSprintf } from '@gitlab/ui';
import GlCountdown from '~/vue_shared/components/gl_countdown.vue';
import {
  ACTIONS_DOWNLOAD_ARTIFACTS,
  ACTIONS_START_NOW,
  ACTIONS_UNSCHEDULE,
  ACTIONS_PLAY,
  ACTIONS_RETRY,
  CANCEL,
  GENERIC_ERROR,
  JOB_SCHEDULED,
  PLAY_JOB_CONFIRMATION_MESSAGE,
  RUN_JOB_NOW_HEADER_TITLE,
} from '../constants';
import eventHub from '../event_hub';
import cancelJobMutation from '../graphql/mutations/job_cancel.mutation.graphql';
import playJobMutation from '../graphql/mutations/job_play.mutation.graphql';
import retryJobMutation from '../graphql/mutations/job_retry.mutation.graphql';
import unscheduleJobMutation from '../graphql/mutations/job_unschedule.mutation.graphql';
import { reportMessageToSentry } from '../../../utils';

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
  computed: {
    artifactDownloadPath() {
      return this.job.artifacts?.nodes[0]?.downloadPath;
    },
    canReadJob() {
      return this.job.userPermissions?.readBuild;
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
      return this.job.userPermissions?.readJobArtifacts && this.job.artifacts?.nodes.length > 0;
    },
  },
  methods: {
    async postJobAction(name, mutation) {
      try {
        const {
          data: {
            [name]: { errors },
          },
        } = await this.$apollo.mutate({
          mutation,
          variables: { id: this.job.id },
        });
        if (errors.length > 0) {
          reportMessageToSentry(this.$options.name, errors.join(', '), {});
          this.showToastMessage();
        } else {
          eventHub.$emit('jobActionPerformed');
        }
      } catch (failure) {
        reportMessageToSentry(this.$options.name, failure, {});
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
      this.postJobAction(this.$options.jobCancel, cancelJobMutation);
    },
    retryJob() {
      this.postJobAction(this.$options.jobRetry, retryJobMutation);
    },
    playJob() {
      this.postJobAction(this.$options.jobPlay, playJobMutation);
    },
    unscheduleJob() {
      this.postJobAction(this.$options.jobUnschedule, unscheduleJobMutation);
    },
  },
};
</script>

<template>
  <gl-button-group>
    <template v-if="canReadJob">
      <gl-button
        v-if="isActive"
        data-testid="cancel-button"
        icon="cancel"
        :title="$options.CANCEL"
        @click="cancelJob()"
      />
      <template v-else-if="isScheduled">
        <gl-button icon="planning" disabled data-testid="countdown">
          <gl-countdown :end-date-string="scheduledAt" />
        </gl-button>
        <gl-button
          v-gl-modal-directive="$options.playJobModalId"
          icon="play"
          :title="$options.ACTIONS_START_NOW"
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
          icon="time-out"
          :title="$options.ACTIONS_UNSCHEDULE"
          data-testid="unschedule"
          @click="unscheduleJob()"
        />
      </template>
      <template v-else>
        <!--Note: This is the manual job play button -->
        <gl-button
          v-if="manualJobPlayable"
          icon="play"
          :title="$options.ACTIONS_PLAY"
          data-testid="play"
          @click="playJob()"
        />
        <gl-button
          v-else-if="isRetryable"
          icon="repeat"
          :title="$options.ACTIONS_RETRY"
          :method="currentJobMethod"
          data-testid="retry"
          @click="retryJob()"
        />
      </template>
    </template>
    <gl-button
      v-if="shouldDisplayArtifacts"
      icon="download"
      :title="$options.ACTIONS_DOWNLOAD_ARTIFACTS"
      :href="artifactDownloadPath"
      rel="nofollow"
      download
      data-testid="download-artifacts"
    />
  </gl-button-group>
</template>
