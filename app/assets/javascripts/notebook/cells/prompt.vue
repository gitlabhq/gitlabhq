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
  },
};
</script>

<template>
  <div class="prompt">
    <span v-if="type && count && showOutput">
      {{ type }} [{{ count }}]:
    </span>
  </div>
</template>

<style scoped>
.prompt {
  padding: 0 10px;
  min-width: 7em;
  font-family: monospace;
}
</style>
