<script>
import { GlButton } from '@gitlab/ui';

export default {
  name: 'StepNav',
  components: {
    GlButton,
  },
  props: {
    showBackButton: {
      type: Boolean,
      required: false,
      default: false,
    },
    showNextButton: {
      type: Boolean,
      required: false,
      default: false,
    },
    nextButtonEnabled: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
};
</script>

<template>
  <div class="gl-flex">
    <slot name="before"></slot>
    <gl-button
      v-if="showBackButton"
      category="secondary"
      data-testid="back-button"
      class="gl-mr-3"
      @click="$emit('back')"
    >
      {{ __('Back') }}
    </gl-button>
    <gl-button
      v-if="showNextButton"
      :disabled="!nextButtonEnabled"
      category="primary"
      data-testid="next-button"
      variant="confirm"
      @click="$emit('next')"
    >
      {{ __('Next') }}
    </gl-button>
    <slot name="after"></slot>
  </div>
</template>

<style scoped></style>
