<script>
import { GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import Prompt from '../prompt.vue';
import Markdown from '../markdown.vue';

export default {
  name: 'MarkdownOutput',
  components: {
    Prompt,
    Markdown,
  },
  directives: {
    SafeHtml,
  },
  props: {
    count: {
      type: Number,
      required: true,
    },
    rawCode: {
      type: Array,
      required: true,
    },
    index: {
      type: Number,
      required: true,
    },
  },
  computed: {
    markdownContent() {
      return { source: this.rawCode };
    },
  },
};
</script>

<template>
  <div class="output">
    <prompt type="Out" :count="count" :show-output="index === 0" />
    <markdown :cell="markdownContent" :hide-prompt="true" />
  </div>
</template>
