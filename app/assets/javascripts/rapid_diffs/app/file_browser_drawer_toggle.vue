<script>
import { GlAnimatedSidebarIcon, GlButton } from '@gitlab/ui';
import { mapActions, mapState } from 'pinia';
import { __ } from '~/locale';
import { useFileBrowser } from '~/diffs/stores/file_browser';

export default {
  name: 'FileBrowserDrawerToggle',
  components: {
    GlButton,
    GlAnimatedSidebarIcon,
  },
  computed: {
    ...mapState(useFileBrowser, ['fileBrowserDrawerVisible']),
    toggleFileBrowserTitle() {
      return this.fileBrowserDrawerVisible ? __('Hide file browser') : __('Show file browser');
    },
  },
  methods: {
    ...mapActions(useFileBrowser, ['toggleFileBrowserDrawerVisibility']),
  },
};
</script>

<template>
  <gl-button
    variant="default"
    category="tertiary"
    class="btn-icon -gl-mr-3 -gl-scale-x-100 lg:gl-hidden"
    :aria-label="toggleFileBrowserTitle"
    data-testid="file-tree-drawer-button"
    @click="toggleFileBrowserDrawerVisibility"
  >
    <gl-animated-sidebar-icon :is-on="fileBrowserDrawerVisible" class="gl-button-icon" />
  </gl-button>
</template>
