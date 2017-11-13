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
    },
  };
</script>

<template>
  <div class="prompt">
    <span v-if="type && count">
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
