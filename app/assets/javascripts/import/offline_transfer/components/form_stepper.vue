<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { scrollToElement } from '~/lib/utils/scroll_utils';
import {
  FORM_STEPPER_TAB_STATE,
  FORM_STEPPER_TAB_COLOR,
  FORM_STEPPER_ACTIVE_TAB_BORDER,
} from '../constants';

export default {
  name: 'FormStepper',
  components: {
    GlButton,
    GlIcon,
  },
  props: {
    steps: {
      type: Array,
      required: true,
      validator: (steps) => steps.every((step) => typeof step === 'string'),
    },
    validateStep: {
      type: Function,
      required: true,
    },
    completionButtonText: {
      type: String,
      required: true,
    },
    canStart: {
      type: Boolean,
      required: false,
      default: true,
    },
    isFormComplete: {
      type: Boolean,
      required: false,
      default: false,
    },
    isSubmitting: {
      type: Boolean,
      required: false,
      default: false,
    },
    isCompletionDisabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['validation-failed', 'complete', 'stepped-back', 'stepped-forward'],

  data() {
    return {
      currentStepIndex: 0,
      isValidating: false,
    };
  },
  computed: {
    isFirstStep() {
      return this.currentStepIndex <= 0;
    },
    isLastStep() {
      return this.currentStepIndex === this.steps.length - 1;
    },
    isFormLocked() {
      return this.isFormComplete || this.isSubmitting;
    },
    showBackButton() {
      return !this.isFirstStep && !this.isFormLocked;
    },
    isStartingBlocked() {
      return this.isFirstStep && !this.canStart;
    },
    showContinueButton() {
      return !this.isLastStep && !this.isStartingBlocked;
    },
    showCompletionButton() {
      return this.isLastStep && !this.isFormComplete;
    },
  },

  methods: {
    getStepIcon(stepIndex) {
      return this.getTabState(stepIndex) === FORM_STEPPER_TAB_STATE.COMPLETED ? 'check' : null;
    },

    getAriaCurrent(stepIndex) {
      return stepIndex === this.currentStepIndex ? 'step' : null;
    },

    getTabState(stepIndex) {
      if (this.isFormComplete) return FORM_STEPPER_TAB_STATE.COMPLETED;
      if (stepIndex === this.currentStepIndex) {
        return FORM_STEPPER_TAB_STATE.ACTIVE;
      }
      if (stepIndex < this.currentStepIndex) return FORM_STEPPER_TAB_STATE.COMPLETED;
      return FORM_STEPPER_TAB_STATE.PENDING;
    },

    getTabClasses(stepIndex) {
      const state = this.getTabState(stepIndex);

      return [
        'gl-pointer-events-none gl-border-0 gl-pb-3 gl-border-solid gl-px-0 gl-mr-6',
        FORM_STEPPER_TAB_COLOR[state],
        state === 'active' && FORM_STEPPER_ACTIVE_TAB_BORDER,
      ];
    },

    async goToNextStep() {
      if (this.isLastStep) return;

      this.isValidating = true;

      try {
        const isValid = await this.validateStep(this.currentStepIndex);

        if (!isValid) {
          this.$emit('validation-failed', this.currentStepIndex);
          this.scrollToCurrentStep();
          return;
        }
      } finally {
        this.isValidating = false;
      }

      const previousTabIndex = this.currentStepIndex;
      this.currentStepIndex += 1;
      this.$emit('stepped-forward', { previousTabIndex });
    },

    // Each step renders its own validation error at the top of its content,
    scrollToCurrentStep() {
      const stepContent = this.$el.querySelector(
        `[data-testid="step-content-${this.currentStepIndex}"]`,
      );

      if (stepContent) {
        scrollToElement(stepContent);
      }
    },

    goToPreviousStep() {
      if (this.isFirstStep) return;

      const previousTabIndex = this.currentStepIndex;
      this.currentStepIndex -= 1;
      this.$emit('stepped-back', { previousTabIndex });
    },

    async handleAllStepsComplete() {
      this.isValidating = true;
      try {
        const isValid = await this.validateStep(this.currentStepIndex);

        if (!isValid) {
          this.$emit('validation-failed', this.currentStepIndex);
          this.scrollToCurrentStep();
          return;
        }
      } finally {
        this.isValidating = false;
      }

      this.$emit('complete');
    },

    // eslint-disable-next-line vue/no-unused-properties -- method triggered from outside of the component
    resetForm() {
      this.currentStepIndex = 0;
      this.isValidating = false;
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-col gl-pt-3">
    <ul class="gl-border-b gl-mb-0 gl-flex gl-list-none gl-p-0">
      <li
        v-for="(step, index) in steps"
        :key="index"
        :class="getTabClasses(index)"
        :aria-current="getAriaCurrent(index)"
        :data-testid="'step-nav-' + index"
      >
        <gl-icon
          v-if="getStepIcon(index)"
          :name="getStepIcon(index)"
          :aria-label="__('Completed')"
          class="gl-mr-2"
        />
        <span v-else class="gl-mr-1">{{ index + 1 }}</span>
        {{ step }}
      </li>
    </ul>

    <div v-for="(step, index) in steps" :key="index">
      <div v-if="index === currentStepIndex" class="gl-pt-6" :data-testid="'step-content-' + index">
        <slot :name="`step-${index}`" :step-data="step" :step-index="index"></slot>
      </div>
    </div>

    <div class="gl-flex gl-gap-3 gl-pt-5">
      <gl-button
        v-if="showBackButton"
        category="secondary"
        data-testid="back-button"
        @click="goToPreviousStep"
      >
        {{ __('Back') }}
      </gl-button>

      <gl-button
        v-if="showContinueButton"
        variant="confirm"
        :disabled="isValidating"
        data-testid="continue-button"
        @click="goToNextStep"
      >
        {{ __('Continue') }}
      </gl-button>

      <gl-button
        v-if="showCompletionButton"
        variant="confirm"
        :disabled="isValidating || isCompletionDisabled"
        :loading="isSubmitting"
        data-testid="completion-button"
        @click="handleAllStepsComplete"
      >
        {{ completionButtonText }}
      </gl-button>
    </div>
  </div>
</template>
