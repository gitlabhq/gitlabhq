<script>
export default {
  name: 'BaseWidget',
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
  <div class="gl-border gl-rounded-pill gl-p-5">
    <slot></slot>
  </div>
</template>
