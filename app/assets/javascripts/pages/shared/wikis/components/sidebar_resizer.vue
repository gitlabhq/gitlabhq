<script>
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

function isScreenMd() {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  return window.matchMedia('(min-width: 768px)').matches;
}

export default {
  components: {
    PanelResizer,
    LocalStorageSync,
  },
  data() {
    return {
      defaultWidth: 290,
      sidebarWidth: 290,
      minWidth: 200,
      maxWidth: 600,
      prevTransitions: {},

      resizeEnabled: isScreenMd(),
    };
  },
  mounted() {
    window.addEventListener('resize', this.updateWidths);

    this.$options.sidebar.classList.remove('gl-hidden');
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.updateWidths);
  },
  methods: {
    removeTransitions() {
      const { sidebar, contentWrapper } = this.$options;

      this.prevTransitions = {
        sidebar: sidebar.style.transition,
        contentWrapper: contentWrapper.style.transition,
      };

      sidebar.style.transition = '0s';
      contentWrapper.style.transition = '0s';
    },
    restoreTransitions() {
      const { sidebar, contentWrapper } = this.$options;

      sidebar.style.transition = this.prevTransitions.sidebar;
      contentWrapper.style.transition = this.prevTransitions.contentWrapper;
    },
    updateWidths(width) {
      if (typeof width === 'number') this.sidebarWidth = width;

      const { sidebar, contentWrapper } = this.$options;

      if (this.resizeEnabled) {
        contentWrapper.style.paddingRight = `${this.sidebarWidth}px`;
        sidebar.style.width = `${this.sidebarWidth}px`;
      } else {
        contentWrapper.style.paddingRight = '';
        sidebar.style.width = '';
      }

      this.resizeEnabled = isScreenMd();
    },
    resetSize() {
      this.sidebarWidth = this.defaultWidth;
      this.updateWidths();
    },
  },
  sidebar: document.querySelector('.js-wiki-sidebar'),
  contentWrapper: document.querySelector('.content-wrapper'),
};
</script>
<template>
  <div role="button" tabindex="0" @dblclick="resetSize">
    <local-storage-sync
      v-model="sidebarWidth"
      storage-key="wiki_sidebar_width"
      @input="updateWidths"
    />
    <panel-resizer
      v-if="resizeEnabled"
      :start-size="sidebarWidth"
      side="left"
      :min-size="minWidth"
      :max-size="maxWidth"
      @resize-start="removeTransitions"
      @resize-end="restoreTransitions"
      @update:size="updateWidths"
    />
  </div>
</template>
