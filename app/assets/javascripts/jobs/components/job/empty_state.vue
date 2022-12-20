<script>
import { GlLink } from '@gitlab/ui';
import ManualVariablesForm from '~/jobs/components/job/manual_variables_form.vue';

export default {
  components: {
    GlLink,
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
  },
  computed: {
    shouldRenderManualVariables() {
      return this.playable && !this.scheduled;
    },
  },
};
</script>
<template>
  <div class="row empty-state">
    <div class="col-12">
      <div :class="illustrationSizeClass" class="svg-content">
        <img :src="illustrationPath" />
      </div>
    </div>

    <div class="col-12">
      <div class="text-content">
        <h4 class="text-center" data-testid="job-empty-state-title">{{ title }}</h4>

        <p v-if="content" data-testid="job-empty-state-content">{{ content }}</p>
      </div>
      <manual-variables-form
        v-if="shouldRenderManualVariables"
        :is-retryable="isRetryable"
        :job-id="jobId"
        @hideManualVariablesForm="$emit('hideManualVariablesForm')"
      />
      <div v-if="action && !shouldRenderManualVariables" class="text-content">
        <div class="text-center">
          <gl-link
            :href="action.path"
            :data-method="action.method"
            class="btn gl-button btn-confirm gl-text-decoration-none!"
            data-testid="job-empty-state-action"
            >{{ action.button_title }}</gl-link
          >
        </div>
      </div>
    </div>
  </div>
</template>
