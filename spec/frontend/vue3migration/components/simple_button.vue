<script>
export default {
  name: 'SimpleButton',
  computed: {
    listeners() {
      // Deliberate white-box read: this fixture regression-tests @vue/compat's
      // $listeners bridge (see hybrid_mode_spec.js).
      // eslint-disable-next-line vue/no-deprecated-dollar-listeners-api
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
