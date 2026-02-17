<script>
export default {
  name: 'ChildEmittingCamelCaseEvent',
  methods: {
    emitEvent() {
      /* eslint-disable vue/custom-event-name-casing, vue/require-explicit-emits */
      this.$emit('customEvent', 'payload');
      /* eslint-enable vue/custom-event-name-casing, vue/require-explicit-emits */
    },
  },
};
</script>

<template>
  <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
  <button data-testid="emit-btn" @click="emitEvent">Emit</button>
</template>
