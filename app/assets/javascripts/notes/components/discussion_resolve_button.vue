<script>
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  name: 'ResolveDiscussionButton',
  components: {
    GlLoadingIcon,
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
  <button ref="button" type="button" class="btn btn-default ml-sm-2" @click="$emit('onClick')">
    <gl-loading-icon v-if="isResolving" ref="isResolvingIcon" inline />
    {{ buttonTitle }}
  </button>
</template>
