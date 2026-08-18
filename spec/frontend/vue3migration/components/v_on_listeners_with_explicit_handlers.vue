<script>
export default {
  name: 'VOnListenersWithExplicitHandlers',
  data() {
    return {
      internalClicks: 0,
    };
  },
  methods: {
    handleClick() {
      this.internalClicks += 1;
    },
  },
};
</script>
<template>
  <!-- Deliberate white-box usage: regression-tests @vue/compat's $listeners
       merge with explicit handlers (see hybrid_mode_spec.js). -->
  <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings, vue/no-deprecated-dollar-listeners-api -->
  <button data-testid="button" v-on="$listeners" @click="handleClick">
    Internal: {{ internalClicks }}
  </button>
</template>
