<script>
export default {
  name: 'SimpleButton',
  computed: {
    listeners() {
      return this.$listeners;
    },
  },
};
</script>
<template>
  <button v-on="listeners">
    <slot></slot>
  </button>
</template>
