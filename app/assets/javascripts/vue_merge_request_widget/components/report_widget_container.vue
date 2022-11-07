<script>
export default {
  data() {
    return {
      hasChildren: false,
    };
  },
  updated() {
    this.hasChildren = this.$scopedSlots.default?.()?.some((c) => c.tag);
  },
};
</script>

<template>
  <div v-show="hasChildren" class="mr-section-container mr-widget-workflow">
    <slot></slot>
  </div>
</template>
