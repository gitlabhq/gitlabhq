<script>
import { GlSafeHtmlDirective } from '@gitlab/ui';
import { sanitize } from '~/lib/dompurify';
import Prompt from '../prompt.vue';

export default {
  components: {
    Prompt,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  props: {
    count: {
      type: Number,
      required: true,
    },
    rawCode: {
      type: String,
      required: true,
    },
    index: {
      type: Number,
      required: true,
    },
  },
  computed: {
    sanitizedOutput() {
      return sanitize(this.rawCode);
    },
    showOutput() {
      return this.index === 0;
    },
  },
};
</script>

<template>
  <div class="output">
    <prompt type="Out" :count="count" :show-output="showOutput" />
    <div v-safe-html="sanitizedOutput" class="gl-overflow-auto"></div>
  </div>
</template>
