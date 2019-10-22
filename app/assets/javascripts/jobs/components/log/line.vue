<script>
import LineNumber from './line_number.vue';

export default {
  components: {
    LineNumber,
  },
  props: {
    line: {
      type: Object,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="js-line log-line">
    <line-number :line-number="line.lineNumber" :path="path" />
    <span
      v-for="(content, i) in line.content"
      :key="i"
      :class="content.style"
      class="ws-pre-wrap"
      >{{ content.text }}</span
    >
  </div>
</template>
