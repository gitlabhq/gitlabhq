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
};
</script>

<template>
  <div class="output">
    <prompt type="Out" :count="count" :show-output="showOutput" />
    <iframe
      sandbox
      :srcdoc="rawCode"
      frameborder="0"
      scrolling="auto"
      width="100%"
      class="gl-overflow-auto"
    ></iframe>
  </div>
</template>
