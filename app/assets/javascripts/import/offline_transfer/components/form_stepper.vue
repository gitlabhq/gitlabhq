<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { FORM_STEPPER_TAB_COLOR, FORM_STEPPER_TAB_BORDER_COLOR } from '../constants';

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
  },
  emits: ['validation-failed', 'complete', 'stepped-back'],

  data() {
    return {
      currentStepIndex: 0,
      isValidating: false,
      isFormComplete: false,
    };
  },
  computed: {
    isFirstStep() {
      return this.currentStepIndex <= 0;
    },
    isLastStep() {
      return this.currentStepIndex === this.steps.length - 1;
    },
    showBackButton() {
      return !this.isFirstStep && !this.isFormComplete;
    },
    showContinueButton() {
      return !this.isLastStep;
    },
    showCompletionButton() {
      return this.isLastStep;
    },
  },

  methods: {
    getStepIcon(stepIndex) {
      return this.getTabState(stepIndex) === 'completed' ? 'check' : null;
    },

    getTabState(stepIndex) {
      if (stepIndex === this.currentStepIndex) {
        return 'active';
      }
      if (stepIndex < this.currentStepIndex) return 'completed';
      return 'pending';
    },

    getTabClasses(stepIndex) {
      const state = this.getTabState(stepIndex);

      return [
        'gl-pointer-events-none gl-border-0 gl-border-b-2 gl-pb-3 gl-border-solid gl-px-0 gl-mr-6',
        FORM_STEPPER_TAB_COLOR[state],
        FORM_STEPPER_TAB_BORDER_COLOR[state],
      ];
    },

    async goToNextStep() {
      if (this.isLastStep) return;

      this.isValidating = true;

      try {
        const isValid = await this.validateStep(this.currentStepIndex);

        if (!isValid) {
          this.$emit('validation-failed', this.currentStepIndex);
          return;
        }
      } finally {
        this.isValidating = false;
      }

      this.currentStepIndex += 1;
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
          return;
        }
      } finally {
        this.isValidating = false;
      }

      this.$emit('complete');
      this.isFormComplete = true;
    },

    // eslint-disable-next-line vue/no-unused-properties -- method triggered from outside of the component
    resetForm() {
      this.currentStepIndex = 0;
      this.isValidating = false;
      this.isFormComplete = false;
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-col">
    <ul class="gl-mb-0 gl-flex gl-list-none gl-p-0">
      <li
        v-for="(step, index) in steps"
        :key="index"
        :class="getTabClasses(index)"
        :data-testid="'step-nav-' + index"
      >
        <gl-icon v-if="getStepIcon(index)" :name="getStepIcon(index)" class="gl-mr-2" />
        <span v-else class="gl-mr-1">{{ index + 1 }}</span>
        {{ step }}
      </li>
    </ul>

    <div v-for="(step, index) in steps" :key="index">
      <div
        v-if="index === currentStepIndex"
        class="gl-min-h-26 gl-py-6"
        :data-testid="'step-content-' + index"
      >
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
        :disabled="isValidating || isFormComplete"
        data-testid="completion-button"
        @click="handleAllStepsComplete"
      >
        {{ completionButtonText }}
      </gl-button>
    </div>
  </div>
</template>
