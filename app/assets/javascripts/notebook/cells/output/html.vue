<script>
import Prompt from '../prompt.vue';

export default {
  props: {
    rawCode: {
      type: String,
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
    <prompt />
    <div v-html="rawCode"></div>
  </div>
</template>
