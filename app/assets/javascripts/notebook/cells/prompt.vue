<!-- eslint-disable vue/multi-word-component-names -->
<script>
export default {
  props: {
    type: {
      type: String,
      required: false,
      default: '',
    },
    count: {
      type: Number,
      required: false,
      default: 0,
    },
    showOutput: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    hasKeys() {
      return this.type !== '' && this.count;
    },
    showTypeText() {
      return this.type && this.count && this.showOutput;
    },
  },
};
</script>

<template>
  <div class="prompt">
    <span v-if="showTypeText"> {{ type }} [{{ count }}]: </span>
  </div>
</template>

<style scoped>
.prompt {
  padding: 0 10px;
  min-width: 7em;
  font-family: monospace;
}
</style>
