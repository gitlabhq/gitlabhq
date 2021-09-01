<script>
import { GlSafeHtmlDirective } from '@gitlab/ui';
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
    showOutput() {
      return this.index === 0;
    },
  },
};
</script>

<template>
  <div class="output">
    <prompt type="Out" :count="count" :show-output="showOutput" />
    <div v-safe-html="rawCode" class="gl-overflow-auto"></div>
  </div>
</template>
