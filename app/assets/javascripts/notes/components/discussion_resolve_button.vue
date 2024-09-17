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
    class="ml-sm-2 gl-w-full sm:gl-w-auto"
    @click="$emit('onClick')"
  >
    {{ buttonTitle }}
  </gl-button>
</template>
