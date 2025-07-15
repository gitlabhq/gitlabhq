<script>
import { GlButton, GlEmptyState } from '@gitlab/ui';
import ManualJobForm from '~/ci/job_details/components/manual_job_form.vue';

export default {
  components: {
    GlButton,
    GlEmptyState,
    ManualJobForm,
  },
  props: {
    illustrationPath: {
      type: String,
      required: true,
    },
    isRetryable: {
      type: Boolean,
      required: true,
    },
    jobId: {
      type: Number,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    content: {
      type: String,
      required: false,
      default: null,
    },
    playable: {
      type: Boolean,
      required: true,
      default: false,
    },
    scheduled: {
      type: Boolean,
      required: false,
      default: false,
    },
    action: {
      type: Object,
      required: false,
      default: null,
      validator(value) {
        return (
          value === null ||
          (Object.prototype.hasOwnProperty.call(value, 'path') &&
            Object.prototype.hasOwnProperty.call(value, 'method') &&
            Object.prototype.hasOwnProperty.call(value, 'button_title'))
        );
      },
    },
    jobName: {
      type: String,
      required: true,
    },
    confirmationMessage: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    shouldRenderManualVariables() {
      return this.playable && !this.scheduled;
    },
  },
};
</script>
<template>
  <gl-empty-state :title="title" :svg-path="illustrationPath">
    <template #description>
      <p v-if="content" class="gl-mb-0 gl-mt-4" data-testid="job-empty-state-content">
        {{ content }}
      </p>
      <manual-job-form
        v-if="shouldRenderManualVariables"
        :is-retryable="isRetryable"
        :job-id="jobId"
        :job-name="jobName"
        :confirmation-message="confirmationMessage"
        @hideManualVariablesForm="$emit('hideManualVariablesForm')"
      />
    </template>
    <template v-if="action && !shouldRenderManualVariables" #actions>
      <gl-button
        :href="action.path"
        :data-method="action.method"
        variant="confirm"
        data-testid="job-empty-state-action"
      >
        {{ action.button_title }}
      </gl-button>
    </template>
  </gl-empty-state>
</template>
