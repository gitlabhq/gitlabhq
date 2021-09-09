<script>
import { GlPopover, GlSafeHtmlDirective } from '@gitlab/ui';
import { glEmojiTag } from '~/emoji';

export default {
  components: {
    GlPopover,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
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
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
};
</script>
<template>
  <span v-if="hasWarnings" class="gl-cursor-default">
    <span :id="htmlId" v-safe-html:[$options.safeHtmlConfig]="glEmojiTag('warning')"></span>
    <gl-popover placement="bottom" :target="htmlId" :content="warningMessage" />
  </span>
</template>
