<script>
export default {
  name: 'CustomEventOnElement',
  data() {
    return {
      handled: false,
    };
  },
  methods: {
    handleCustomEvent() {
      this.handled = true;
    },
  },
};
</script>

<template>
  <div data-testid="container" @customEvent="handleCustomEvent">
    <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
    <span v-if="handled" data-testid="handled">Handled</span>
  </div>
</template>
