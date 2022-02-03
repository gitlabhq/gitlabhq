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
  safeHtmlConfig: {
    ADD_TAGS: ['use'], // to support icon SVGs
    FORBID_TAGS: ['style'],
    FORBID_ATTR: ['style'],
    ALLOW_DATA_ATTR: false,
  },
};
</script>

<template>
  <div class="output">
    <prompt type="Out" :count="count" :show-output="showOutput" />
    <div v-safe-html:[$options.safeHtmlConfig]="rawCode" class="gl-overflow-auto"></div>
  </div>
</template>
