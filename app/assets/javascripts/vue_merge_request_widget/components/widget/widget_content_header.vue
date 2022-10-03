<script>
import { GlSafeHtmlDirective } from '@gitlab/ui';
import { generateText } from '../extensions/utils';

export default {
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  props: {
    header: {
      type: [String, Array],
      default: '',
      required: false,
    },
  },
  computed: {
    generatedHeader() {
      return generateText(Array.isArray(this.header) ? this.header[0] : this.header);
    },
    generatedSubheader() {
      return Array.isArray(this.header) && this.header[1] ? generateText(this.header[1]) : '';
    },
  },
};
</script>
<template>
  <div class="gl-mb-2">
    <strong v-safe-html="generatedHeader" class="gl-display-block"></strong
    ><span
      v-if="generatedSubheader"
      v-safe-html="generatedSubheader"
      class="gl-display-block"
    ></span>
  </div>
</template>
