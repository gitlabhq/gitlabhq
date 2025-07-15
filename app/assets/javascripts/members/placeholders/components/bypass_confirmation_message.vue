<script>
import { GlSprintf } from '@gitlab/ui';
import { ALLOW_BYPASS_PLACEHOLDER_CONFIRMATION_MESSAGE } from '~/members/constants';

export default {
  name: 'BypassConfirmationMessage',
  components: {
    GlSprintf,
  },
  inject: {
    allowBypassPlaceholderConfirmation: {
      default: null,
    },
  },
  computed: {
    bypassConfirmationMessage() {
      return (
        ALLOW_BYPASS_PLACEHOLDER_CONFIRMATION_MESSAGE[this.allowBypassPlaceholderConfirmation] ||
        null
      );
    },
  },
};
</script>

<template>
  <span v-if="bypassConfirmationMessage">
    <gl-sprintf :message="bypassConfirmationMessage">
      <template #strong="{ content }">
        <strong>{{ content }}</strong>
      </template>
    </gl-sprintf>
  </span>
</template>
