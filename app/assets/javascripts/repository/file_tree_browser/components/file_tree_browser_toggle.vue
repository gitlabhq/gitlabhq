<script>
import { GlButton } from '@gitlab/ui';
import { mapState, mapActions } from 'pinia';
import { __ } from '~/locale';
import { useFileTreeBrowserVisibility } from '~/repository/stores/file_tree_browser_visibility';

export default {
  name: 'FileTreeBrowserDrawerToggle',
  components: {
    GlButton,
  },
  computed: {
    ...mapState(useFileTreeBrowserVisibility, ['fileTreeBrowserVisible']),
    toggleFileBrowserTitle() {
      return this.fileTreeBrowserVisible
        ? __('Hide file tree browser')
        : __('Show file tree browser');
    },
  },
  methods: {
    ...mapActions(useFileTreeBrowserVisibility, ['toggleFileTreeVisibility']),
  },
};
</script>

<template>
  <gl-button
    icon="file-tree"
    :aria-label="toggleFileBrowserTitle"
    @click="toggleFileTreeVisibility"
  />
</template>
