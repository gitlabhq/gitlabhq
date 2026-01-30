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
    };
  },
  mounted() {
    window.addEventListener('resize', this.updateWidths);
    this.updateWidths();
    this.getSidebarContainer().classList.remove('gl-hidden');
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.updateWidths);
  },
  methods: {
    getSidebarContainer() {
      return document.querySelector('.sidebar-container');
    },
    getSidebar() {
      return document.querySelector('.wiki-sidebar');
    },
    updateSidebarWidth(width) {
      const el = this.getSidebarContainer();
      el.style.width = width;
    },
    removeTransitions() {
      this.getSidebar().classList.remove('transition-enabled');
    },
    restoreTransitions() {
      this.getSidebar().classList.add('transition-enabled');
    },
    updateWidths(width) {
      this.removeTransitions();

      if (typeof width === 'number') this.sidebarWidth = width;

      this.updateSidebarWidth(`${this.sidebarWidth}px`);

      requestAnimationFrame(this.restoreTransitions);
    },
    resetSize() {
      this.sidebarWidth = this.defaultWidth;
      this.updateWidths();
    },
  },
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
