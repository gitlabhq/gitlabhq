<script>
export default {
  props: {
    open: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <transition name="design-disclosure">
    <aside
      v-if="open"
      class="design-disclosure gl-w-full gl-display-flex gl-flex-direction-column gl-relative gl-border-l gl-z-index-0 gl-bg-white gl-top-0 gl-right-0 gl-h-full gl-overflow-y-auto"
    >
      <slot></slot>
    </aside>
  </transition>
</template>
