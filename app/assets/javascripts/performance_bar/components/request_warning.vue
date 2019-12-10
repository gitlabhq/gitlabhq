<script>
import { GlPopover } from '@gitlab/ui';
import { glEmojiTag } from '~/emoji';

export default {
  components: {
    GlPopover,
  },
  props: {
    htmlId: {
      type: String,
      required: true,
    },
    warnings: {
      type: Array,
      required: true,
    },
  },
  computed: {
    hasWarnings() {
      return this.warnings && this.warnings.length;
    },
    warningMessage() {
      if (!this.hasWarnings) {
        return '';
      }

      return this.warnings.join('\n');
    },
  },
  methods: {
    glEmojiTag,
  },
};
</script>
<template>
  <span v-if="hasWarnings">
    <span :id="htmlId" v-html="glEmojiTag('warning')"></span>
    <gl-popover :target="htmlId" :content="warningMessage" triggers="hover focus" />
  </span>
</template>
