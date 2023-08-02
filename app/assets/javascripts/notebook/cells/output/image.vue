<!-- eslint-disable vue/multi-word-component-names -->
<script>
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
    outputType: {
      type: String,
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
    imgSrc() {
      return `data:${this.outputType};base64,${this.rawCode}`; // eslint-disable-line @gitlab/require-i18n-strings
    },
    showOutput() {
      return this.index === 0;
    },
  },
};
</script>

<template>
  <div class="output">
    <prompt type="out" :count="count" :show-output="showOutput" /> <img :src="imgSrc" />
  </div>
</template>
