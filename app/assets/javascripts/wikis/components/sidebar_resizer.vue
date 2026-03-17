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
    this.applySidebarWidth();
    this.getSidebarContainer().classList.remove('gl-hidden');
  },
  methods: {
    getSidebarContainer() {
      return document.querySelector('.sidebar-container');
    },
    getSidebar() {
      return document.querySelector('.wiki-sidebar');
    },
    removeTransitions() {
      this.getSidebar().classList.remove('transition-enabled');
    },
    restoreTransitions() {
      this.getSidebar().classList.add('transition-enabled');
    },
    applySidebarWidth() {
      this.getSidebarContainer().style.width = `${this.sidebarWidth}px`;
    },
    updateWidth(width) {
      this.removeTransitions();
      this.sidebarWidth = width;
      this.applySidebarWidth();
      requestAnimationFrame(this.restoreTransitions);
    },
    resetSize() {
      this.updateWidth(this.defaultWidth);
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
      @input="updateWidth"
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
      @update:size="updateWidth"
    />
  </div>
</template>
