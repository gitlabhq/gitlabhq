<script>
import Prompt from '../prompt.vue';
import Markdown from '../markdown.vue';

export default {
  name: 'ErrorOutput',
  components: {
    Prompt,
    Markdown,
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
    parsedError() {
      let parsed = this.rawCode.map((l) => l.replace(/\u001B\[[0-9][0-9;]*m/g, '')); // eslint-disable-line no-control-regex
      parsed = ['```error', ...parsed, '```'].join('\n'); // eslint-disable-line @gitlab/require-i18n-strings
      return { source: [parsed] };
    },
  },
};
</script>

<template>
  <div class="output">
    <prompt type="Out" :count="count" />
    <markdown :cell="parsedError" :hide-prompt="true" />
  </div>
</template>
