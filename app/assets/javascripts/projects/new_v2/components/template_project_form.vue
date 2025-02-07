<script>
import { GlButton } from '@gitlab/ui';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';

export default {
  components: {
    GlButton,
    MultiStepFormTemplate,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <multi-step-form-template :title="title" :current-step="2" :steps-total="3">
    <template #next>
      <gl-button category="primary" variant="confirm" :disabled="true">
        {{ __('Next step') }}
      </gl-button>
    </template>
    <template #back>
      <gl-button category="primary" variant="default">
        {{ __('Go back') }}
      </gl-button>
    </template>
  </multi-step-form-template>
</template>
