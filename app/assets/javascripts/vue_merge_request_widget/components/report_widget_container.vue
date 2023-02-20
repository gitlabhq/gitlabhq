<script>
export default {
  data() {
    return {
      hasChildren: false,
    };
  },
  mounted() {
    const setHasChildren = () => {
      this.hasChildren = Boolean(this.$el.innerText.trim());
    };

    // Set initial.
    setHasChildren();

    if (!this.hasChildren) {
      // Observe children changed.
      this.observer = new MutationObserver(() => {
        setHasChildren();

        if (this.hasChildren) {
          this.observer.disconnect();
          this.observer = undefined;
        }
      });

      this.observer.observe(this.$el, { childList: true, subtree: true });
    }
  },
  beforeUnmount() {
    if (this.observer) {
      this.observer.disconnect();
    }
  },
};
</script>

<template>
  <div v-show="hasChildren" class="mr-section-container mr-widget-workflow">
    <slot></slot>
  </div>
</template>
