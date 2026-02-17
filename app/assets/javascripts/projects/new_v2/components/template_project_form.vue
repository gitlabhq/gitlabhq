<script>
import { GlButton, GlMultiStepFormTemplate } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlMultiStepFormTemplate,
  },
  props: {
    option: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
};
</script>

<template>
  <gl-multi-step-form-template :title="option.title" :current-step="2" :steps-total="3">
    <template #next>
      <gl-button
        category="primary"
        variant="confirm"
        :disabled="true"
        data-testid="template-project-next-button"
      >
        {{ __('Next step') }}
      </gl-button>
    </template>
    <template #back>
      <gl-button
        category="primary"
        variant="default"
        data-testid="template-project-back-button"
        @click="$emit('back')"
      >
        {{ __('Go back') }}
      </gl-button>
    </template>
  </gl-multi-step-form-template>
</template>
