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
  <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
  <button data-testid="button" v-on="$listeners" @click="handleClick">
    Internal: {{ internalClicks }}
  </button>
</template>
