<script>
export default {
  data() {
    return {
      hasChildren: false,
    };
  },
  updated() {
    this.hasChildren = this.checkSlots();
  },
  mounted() {
    this.hasChildren = this.checkSlots();
  },
  methods: {
    checkSlots() {
      return this.$scopedSlots.default?.()?.some((c) => c.tag);
    },
  },
};
</script>

<template>
  <div v-show="hasChildren" class="mr-section-container mr-widget-workflow">
    <slot></slot>
  </div>
</template>
