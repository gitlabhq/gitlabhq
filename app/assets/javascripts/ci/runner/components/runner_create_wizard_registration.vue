<script>
import { GlButton } from '@gitlab/ui';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';

export default {
  components: {
    GlButton,
    MultiStepFormTemplate,
  },
  props: {
    currentStep: {
      type: Number,
      required: true,
    },
    stepsTotal: {
      type: Number,
      required: true,
    },
  },
};
</script>
<template>
  <multi-step-form-template
    :title="s__('Runners|Register your new runner')"
    :current-step="currentStep"
    :steps-total="stepsTotal"
  >
    <template #form>
      <!-- Content will be added in https://gitlab.com/gitlab-org/gitlab/-/issues/396544 -->
    </template>
    <template #back>
      <gl-button category="primary" variant="default" :disabled="true">
        {{ s__('Runners|View runners') }}
      </gl-button>
    </template>
  </multi-step-form-template>
</template>
