<script>
export default {
  name: 'KeydownSpaceHandler',
  data() {
    return {
      activated: false,
    };
  },
  methods: {
    handleSpace() {
      this.activated = true;
    },
  },
};
</script>

<template>
  <div data-testid="container" @keydown.space="handleSpace">
    <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
    <span v-if="activated" data-testid="activated">Activated</span>
  </div>
</template>
