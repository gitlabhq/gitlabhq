<script>
  export default {
    props: {
      type: {
        type: String,
        required: false,
      },
      count: {
        type: Number,
        required: false,
      },
      showOutput: {
        type: Boolean,
        required: false,
        default: true,
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
