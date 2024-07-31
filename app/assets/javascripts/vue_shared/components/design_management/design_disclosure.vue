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
      class="design-disclosure gl-border-l gl-relative gl-right-0 gl-top-0 gl-z-0 gl-flex gl-h-full gl-w-full gl-flex-col gl-overflow-y-auto gl-bg-white"
    >
      <slot></slot>
    </aside>
  </transition>
</template>
