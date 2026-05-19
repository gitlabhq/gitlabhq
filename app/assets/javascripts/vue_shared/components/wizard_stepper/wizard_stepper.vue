<script>
import { GlIcon } from '@gitlab/ui';
import { uniqueId } from 'lodash-es';
import { s__ } from '~/locale';

export default {
  name: 'WizardStepper',
  components: { GlIcon },
  i18n: {
    defaultErrorMessage: s__('WizardStepper|Step has validation errors'),
  },
  props: {
    steps: {
      type: Array,
      required: true,
    },
    currentStep: {
      type: Number,
      required: true,
    },
  },
  emits: ['step-click'],
  data() {
    return {
      uniqueIdPrefix: uniqueId('wizard-stepper-'),
    };
  },
  computed: {
    isInteractive() {
      return Boolean(this.$listeners['step-click']);
    },
    stepTag() {
      return this.isInteractive ? 'button' : 'div';
    },
  },
  methods: {
    isError(step) {
      return Boolean(step.error);
    },
    isDisabled(step) {
      return Boolean(step.disabled);
    },
    isDone(step) {
      return !this.isError(step) && !this.isDisabled(step) && step.id < this.currentStep;
    },
    isCurrent(step) {
      return step.id === this.currentStep;
    },
    isClickable(step) {
      return this.isInteractive && !this.isDisabled(step);
    },
    handleClick(step) {
      if (!this.isClickable(step)) return;
      this.$emit('step-click', step.id);
    },
    errorMessageId(step) {
      return `${this.uniqueIdPrefix}-error-${step.id}`;
    },
    errorMessageText(step) {
      return step.errorMessage || this.$options.i18n.defaultErrorMessage;
    },
    labelClasses(step) {
      if (this.isError(step)) return ['gl-text-status-danger'];
      if (this.isCurrent(step)) return ['gl-font-bold'];
      return ['gl-text-subtle'];
    },
    indicatorClasses(step) {
      if (this.isCurrent(step)) {
        return 'gl-bg-status-info gl-text-status-info gl-font-bold';
      }
      return 'gl-bg-strong gl-text-subtle';
    },
    stepRootClasses(step) {
      // When the stepper is interactive every step renders as a <button>; reset the
      // browser default border/background/padding so disabled and clickable steps
      // share the visual baseline of the non-interactive (<div>) variant.
      return {
        'gl-border-0 gl-bg-transparent gl-p-0': this.isInteractive,
        'gl-cursor-pointer': this.isClickable(step),
        'gl-cursor-not-allowed': this.isInteractive && this.isDisabled(step),
      };
    },
  },
};
</script>

<template>
  <div class="gl-mb-6 gl-flex gl-items-center">
    <template v-for="(step, index) in steps">
      <component
        :is="stepTag"
        :key="`step-${step.id}`"
        :type="stepTag === 'button' ? 'button' : null"
        :disabled="stepTag === 'button' && isDisabled(step) ? true : null"
        :aria-disabled="isDisabled(step) ? 'true' : null"
        :aria-invalid="isError(step) ? 'true' : null"
        :aria-describedby="isError(step) ? errorMessageId(step) : null"
        :data-testid="`step-${step.id}`"
        class="gl-flex gl-items-center gl-gap-2"
        :class="stepRootClasses(step)"
        @click="handleClick(step)"
      >
        <gl-icon
          v-if="isError(step)"
          name="error"
          class="gl-text-status-danger"
          data-testid="step-icon-error"
        />
        <gl-icon
          v-else-if="isDone(step)"
          name="check-circle-filled"
          class="gl-text-status-success"
          data-testid="step-icon-done"
        />
        <span
          v-else
          class="gl-flex gl-h-6 gl-w-6 gl-items-center gl-justify-center gl-rounded-full gl-text-sm"
          :class="indicatorClasses(step)"
          data-testid="step-indicator"
          >{{ step.id }}</span
        >
        <span :class="labelClasses(step)" data-testid="step-label">{{ step.label }}</span>
        <span
          v-if="isError(step)"
          :id="errorMessageId(step)"
          class="gl-sr-only"
          data-testid="step-error-message"
          >{{ errorMessageText(step) }}</span
        >
      </component>
      <div
        v-if="index < steps.length - 1"
        :key="`connector-${step.id}`"
        class="gl-mx-3 gl-h-px gl-flex-1 gl-bg-strong"
        aria-hidden="true"
      ></div>
    </template>
  </div>
</template>
