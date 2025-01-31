<script>
import { sprintf, __ } from '~/locale';

export default {
  name: 'MultiStepFormTemplate',
  props: {
    title: {
      type: String,
      required: true,
    },
    currentStep: {
      type: Number,
      required: true,
    },
    stepsTotal: {
      type: Number,
      required: false,
      default: null,
    },
  },
  computed: {
    stepMessage() {
      return this.stepsTotal
        ? sprintf(__('Step %{currentStep} of %{stepsTotal}'), {
            currentStep: this.currentStep,
            stepsTotal: this.stepsTotal,
          })
        : sprintf(__('Step %{currentStep}'), { currentStep: this.currentStep });
    },
  },
};
</script>
<template>
  <div class="multi-step-form gl-mx-auto gl-pt-8">
    <h1 class="gl-heading-1 gl-mb-3 gl-mt-0 gl-text-center" data-testid="multi-step-form-title">
      {{ title }}
    </h1>
    <p class="gl-m-0 gl-text-center" data-testid="multi-step-form-steps">{{ stepMessage }}</p>
    <div class="gl-mt-7" data-testid="multi-step-form-content">
      <slot name="form"></slot>
    </div>
    <div
      v-if="$scopedSlots.back || $scopedSlots.next"
      class="gl-mt-6 gl-flex gl-justify-center gl-gap-3"
      data-testid="multi-step-form-action"
    >
      <slot name="back"></slot>
      <slot name="next"></slot>
    </div>
    <div v-if="$scopedSlots.footer" class="gl-mt-7" data-testid="multi-step-form-footer">
      <slot name="footer"></slot>
    </div>
  </div>
</template>
