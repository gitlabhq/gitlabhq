<script>
import Prompt from '../prompt.vue';

export default {
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
  components: {
    prompt: Prompt,
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
    <div v-html="rawCode"></div>
  </div>
</template>
