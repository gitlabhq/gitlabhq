<script>
import { GlButton, GlIcon, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import { reportToSentry } from '~/ci/utils';
import cancelJobMutation from '~/ci/pipeline_mini_graph/graphql/mutations/job_cancel.mutation.graphql';
import playJobMutation from '~/ci/pipeline_mini_graph/graphql/mutations/job_play.mutation.graphql';
import retryJobMutation from '~/ci/pipeline_mini_graph/graphql/mutations/job_retry.mutation.graphql';
import unscheduleJobMutation from '~/ci/pipeline_mini_graph/graphql/mutations/job_unschedule.mutation.graphql';
import JobActionModal from './job_action_modal.vue';

export const i18n = {
  errors: {
    cancelJob: s__('Pipeline|There was a problem canceling the job.'),
    playJob: s__('Pipeline|There was a problem running the job.'),
    retryJob: s__('Pipeline|There was a problem running the job again.'),
    unscheduleJob: s__('Pipeline|There was a problem unscheduling the job.'),
  },
};

export default {
  name: 'JobActionButton',
  JOB_ACTIONS: {
    cancel: {
      dataName: 'jobCancel',
      error: i18n.errors.cancelJob,
      mutation: cancelJobMutation,
    },
    play: {
      dataName: 'jobPlay',
      error: i18n.errors.playJob,
      mutation: playJobMutation,
    },
    retry: {
      dataName: 'jobRetry',
      error: i18n.errors.retryJob,
      mutation: retryJobMutation,
    },
    'time-out': {
      dataName: 'jobUnschedule',
      error: i18n.errors.unscheduleJob,
      mutation: unscheduleJobMutation,
    },
  },
  i18n,
  components: {
    GlButton,
    GlIcon,
    GlLoadingIcon,
    JobActionModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    jobId: {
      type: String,
      required: true,
    },
    jobAction: {
      type: Object,
      required: true,
    },
    jobName: {
      type: String,
      required: true,
    },
  },
  emits: ['jobActionExecuted'],
  data() {
    return {
      isLoading: false,
      showConfirmationModal: false,
    };
  },
  computed: {
    actionType() {
      return this.jobAction.icon;
    },
    hasConfirmationModal() {
      return this.jobAction?.confirmationMessage !== null;
    },
  },
  methods: {
    onActionButtonClick() {
      if (this.hasConfirmationModal) {
        this.showConfirmationModal = true;
      } else {
        this.executeJobAction();
      }
    },
    async executeJobAction() {
      try {
        this.isLoading = true;
        const {
          data: {
            [this.$options.JOB_ACTIONS[this.actionType].dataName]: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: this.$options.JOB_ACTIONS[this.actionType].mutation,
          variables: { id: this.jobId },
        });
        if (errors.length) {
          reportToSentry(this.$options.name, new Error(errors.join(', ')));
        }
      } catch (error) {
        createAlert({ message: this.$options.JOB_ACTIONS[this.actionType].error });
        reportToSentry(this.$options.name, error);
      } finally {
        this.isLoading = false;
        this.$emit('jobActionExecuted');
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-button
      v-gl-tooltip.viewport.left
      :title="jobAction.title"
      :aria-label="jobAction.title"
      :disabled="isLoading"
      size="small"
      class="gl-h-6 gl-w-6 !gl-rounded-full !gl-p-0"
      data-testid="ci-action-button"
      @click.prevent="onActionButtonClick"
    >
      <gl-loading-icon v-if="isLoading" size="sm" class="gl-m-2" />
      <gl-icon v-else :name="jobAction.icon" :size="12" />
    </gl-button>
    <job-action-modal
      v-if="hasConfirmationModal"
      v-model="showConfirmationModal"
      :job-name="jobName"
      :custom-message="jobAction.confirmationMessage"
      @confirm="executeJobAction"
    />
  </div>
</template>
