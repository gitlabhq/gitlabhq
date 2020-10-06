<script>
import { GlButton } from '@gitlab/ui';

export default {
  name: 'ReplyPlaceholder',
  components: {
    GlButton,
  },
  props: {
    buttonText: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <gl-button
    category="primary"
    variant="success"
    class="js-vue-discussion-reply"
    :title="s__('MergeRequests|Add a reply')"
    @click="$emit('onClick')"
  >
    {{ buttonText }}
  </gl-button>
</template>
