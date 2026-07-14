<script>
import { GlButton } from '@gitlab/ui';

export default {
  name: 'SignupSubmitButton',
  components: {
    GlButton,
  },
  props: {
    buttonText: {
      type: String,
      required: true,
    },
    buttonClass: {
      type: String,
      required: false,
      default: '',
    },
    trackLabel: {
      type: String,
      required: false,
      default: '',
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <gl-button
    type="submit"
    variant="confirm"
    block
    :loading="loading"
    :class="buttonClass"
    data-testid="new-user-register-button"
    data-track-action="register"
    :data-track-label="trackLabel"
  >
    {{ buttonText }}
  </gl-button>
</template>
