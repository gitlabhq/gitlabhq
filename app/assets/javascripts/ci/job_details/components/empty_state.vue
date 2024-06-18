<script>
import { GlButton } from '@gitlab/ui';
import ManualVariablesForm from '~/ci/job_details/components/manual_variables_form.vue';

export default {
  components: {
    GlButton,
    ManualVariablesForm,
  },
  props: {
    illustrationPath: {
      type: String,
      required: true,
    },
    illustrationSizeClass: {
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
  <div class="gl-display-flex gl-empty-state gl-text-center gl-flex-direction-column">
    <div :class="illustrationSizeClass" class="gl-max-w-full">
      <!-- eslint-disable @gitlab/vue-require-i18n-attribute-strings -->
      <img alt="" class="gl-max-w-full" :src="illustrationPath" />
    </div>
    <div class="gl-empty-state-content gl-mx-auto gl-my-0 gl-m-auto gl-p-5">
      <h1
        class="gl-font-size-h-display gl-leading-36 gl-mt-0 gl-mb-0"
        data-testid="job-empty-state-title"
      >
        {{ title }}
      </h1>
      <p v-if="content" class="gl-mt-4 gl-mb-0" data-testid="job-empty-state-content">
        {{ content }}
      </p>
      <manual-variables-form
        v-if="shouldRenderManualVariables"
        :is-retryable="isRetryable"
        :job-id="jobId"
        :job-name="jobName"
        :confirmation-message="confirmationMessage"
        @hideManualVariablesForm="$emit('hideManualVariablesForm')"
      />
      <div
        v-if="action && !shouldRenderManualVariables"
        class="gl-display-flex gl-flex-wrap gl-mt-5 gl-justify-content-center"
      >
        <gl-button
          :href="action.path"
          :data-method="action.method"
          variant="confirm"
          data-testid="job-empty-state-action"
          >{{ action.button_title }}</gl-button
        >
      </div>
    </div>
  </div>
</template>
