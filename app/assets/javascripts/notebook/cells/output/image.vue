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
      return `data:${this.outputType};base64,${this.rawCode}`;
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
    <img
      :src="imgSrc"
    />
  </div>
</template>
