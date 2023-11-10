<script>
import { GlButton } from '@gitlab/ui';

export default {
  name: 'ResolveDiscussionButton',
  components: {
    GlButton,
  },
  props: {
    isResolving: {
      type: Boolean,
      required: false,
      default: false,
    },
    buttonTitle: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <gl-button
    :loading="isResolving"
    class="gl-w-full gl-sm-w-auto ml-sm-2"
    @click="$emit('onClick')"
  >
    {{ buttonTitle }}
  </gl-button>
</template>
