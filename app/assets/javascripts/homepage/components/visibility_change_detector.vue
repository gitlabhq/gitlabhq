<script>
export default {
  name: 'VisibilityChangeDetector',
  mounted() {
    document.addEventListener('visibilitychange', this.handleVisibilityChanged);
  },
  beforeDestroy() {
    document.removeEventListener('visibilitychange', this.handleVisibilityChanged);
  },
  methods: {
    handleVisibilityChanged() {
      if (!document.hidden) {
        this.$emit('visible');
      }
    },
  },
};
</script>

<template>
  <div>
    <slot></slot>
  </div>
</template>
