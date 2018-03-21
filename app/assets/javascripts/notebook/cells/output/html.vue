<script>
import sanitize from 'sanitize-html';
import Prompt from '../prompt.vue';

export default {
  components: {
    Prompt,
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
      return sanitize(this.rawCode, {
        allowedTags: sanitize.defaults.allowedTags.concat(['img', 'svg']),
        allowedAttributes: {
          img: ['src'],
        },
      });
    },
  },
};
</script>

<template>
  <div class="output">
    <prompt
      type="out"
      :count="count"
      :show-output="index === 0"
    />
    <div v-html="sanitizedOutput"></div>
  </div>
</template>
