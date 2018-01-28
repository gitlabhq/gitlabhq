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
    <span v-if="hasKeys">
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
