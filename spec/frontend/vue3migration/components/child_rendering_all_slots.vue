<script>
export default {
  name: 'ChildRenderingAllSlots',
  // This fixture deliberately iterates $scopedSlots in the template: it
  // covers the compat pass-through slot order (preserve-slot-order.patch,
  // see hybrid_mode_spec.js). Keep the compat feature enabled locally so it
  // keeps testing that path regardless of the global key in
  // compat_config.js (inert under Vue 2, silent in census mode).
  compatConfig: { INSTANCE_SCOPED_SLOTS: 'suppress-warning' },
};
</script>
<template>
  <div>
    <!-- eslint-disable-next-line vue/no-v-for-template-key -->
    <template v-for="(_, name) in $scopedSlots">
      <div :key="name" :data-testid="'slot-' + name">
        <!-- eslint-disable-next-line vue/html-self-closing -->
        <slot :name="name"></slot>
      </div>
    </template>
  </div>
</template>
