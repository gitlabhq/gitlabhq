<script>
import Prompt from '../prompt.vue';

export default {
  props: {
    outputType: {
      type: String,
      required: true,
    },
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
    <img
      :src="'data:' + outputType + ';base64,' + rawCode" />
  </div>
</template>
