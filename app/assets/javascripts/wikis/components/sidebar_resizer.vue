<script>
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

export default {
  components: {
    PanelResizer,
    LocalStorageSync,
  },
  data() {
    return {
      defaultWidth: 220,
      sidebarWidth: 220,
      minWidth: 200,
      maxWidth: 600,
      prevTransitions: {},
    };
  },
  mounted() {
    window.addEventListener('resize', this.updateWidths);
    this.updateWidths();
    this.$options.sidebar.classList.remove('gl-hidden');
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.updateWidths);
  },
  methods: {
    removeTransitions() {
      const { sidebar } = this.$options;

      this.prevTransitions = {
        sidebar: sidebar.style.transition,
      };

      sidebar.style.transition = '0s';
    },
    restoreTransitions() {
      const { sidebar } = this.$options;

      sidebar.style.transition = this.prevTransitions.sidebar;
    },
    updateWidths(width) {
      if (typeof width === 'number') this.sidebarWidth = width;

      const { sidebar } = this.$options;

      sidebar.style.width = `${this.sidebarWidth}px`;

      this.resizeEnabled = true;
    },
    resetSize() {
      this.sidebarWidth = this.defaultWidth;
      this.updateWidths();
    },
  },
  sidebar: document.querySelector('.sidebar-container'),
};
</script>
<template>
  <div
    role="button"
    :title="__('Resize sidebar')"
    tabindex="0"
    class="resizer"
    @dblclick="resetSize"
  >
    <local-storage-sync
      v-model="sidebarWidth"
      storage-key="wiki_sidebar_width"
      @input="updateWidths"
    />
    <panel-resizer
      :start-size="sidebarWidth"
      side="right"
      :min-size="minWidth"
      :max-size="maxWidth"
      enabled
      class="gl-z-4"
      @resize-start="removeTransitions"
      @resize-end="restoreTransitions"
      @update:size="updateWidths"
    />
  </div>
</template>
