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
  <span v-if="hasWarnings" class="gl-cursor-default">
    <span
      :id="htmlId"
      v-html="glEmojiTag('warning') /* eslint-disable-line vue/no-v-html */"
    ></span>
    <gl-popover placement="bottom" :target="htmlId" :content="warningMessage" />
  </span>
</template>
