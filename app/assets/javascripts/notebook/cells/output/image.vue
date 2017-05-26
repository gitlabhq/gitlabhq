<script>
import Prompt from '../prompt.vue';

export default {
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
    <img
      :src="'data:' + outputType + ';base64,' + rawCode" />
  </div>
</template>
