<script>
const getLayoutPage = () => document.querySelector('.layout-page');

export default {
  props: {
    expanded: {
      type: Boolean,
      required: true,
    },
  },
  watch: {
    expanded(value) {
      const layoutPageEl = getLayoutPage();

      if (layoutPageEl) {
        layoutPageEl.classList.toggle('right-sidebar-expanded', value);
        layoutPageEl.classList.toggle('right-sidebar-collapsed', !value);
      }
    },
  },
  mounted() {
    const layoutPageEl = getLayoutPage();

    if (layoutPageEl) {
      layoutPageEl.classList.add('issuable-bulk-update-sidebar');
    }
  },
};
</script>

<template>
  <aside
    :class="{ 'right-sidebar-expanded': expanded, 'right-sidebar-collapsed': !expanded }"
    class="issues-bulk-update right-sidebar"
    aria-live="polite"
  >
    <div class="gl-border-b gl-flex gl-justify-between gl-p-4">
      <slot name="bulk-edit-actions"></slot>
    </div>
    <slot name="sidebar-items"></slot>
  </aside>
</template>
