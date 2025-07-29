<script>
import { mapState } from 'pinia';
import { MountingPortal } from 'portal-vue';
import { GlDrawer } from '@gitlab/ui';
import DiffsFileTree from '~/diffs/components/diffs_file_tree.vue';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';

export default {
  name: 'FileBrowserDrawer',
  DRAWER_Z_INDEX,
  components: {
    MountingPortal,
    DiffsFileTree,
    GlDrawer,
  },
  props: {
    groupBlobsListItems: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      openedOnce: false,
    };
  },
  computed: {
    ...mapState(useDiffsView, ['totalFilesCount']),
    ...mapState(useDiffsList, ['loadedFiles']),
    ...mapState(useFileBrowser, ['fileBrowserDrawerVisible']),
  },
  watch: {
    fileBrowserDrawerVisible() {
      this.openedOnce = true;
    },
  },
  beforeDestroy() {
    useFileBrowser().setFileBrowserDrawerVisibility(false);
  },
  methods: {
    clickFile(file) {
      this.$emit('clickFile', file);
      this.close();
    },
    toggleFolder(path) {
      useLegacyDiffs().toggleTreeOpen(path);
    },
    close() {
      useFileBrowser().setFileBrowserDrawerVisibility(false);
    },
  },
};
</script>

<template>
  <mounting-portal append mount-to="#js-drawer-container">
    <gl-drawer
      v-show="fileBrowserDrawerVisible"
      :open="openedOnce"
      :z-index="$options.DRAWER_Z_INDEX"
      header-sticky
      @close="close"
    >
      <template #title>
        <h2 class="gl-my-0 gl-text-size-h2 gl-leading-24">{{ s__('RapidDiffs|File browser') }}</h2>
      </template>
      <template #default>
        <diffs-file-tree
          class="diffs-tree-drawer"
          :loaded-files="loadedFiles"
          :total-files-count="totalFilesCount"
          :group-blobs-list-items="groupBlobsListItems"
          @clickFile="clickFile"
          @toggleFolder="toggleFolder"
        />
      </template>
    </gl-drawer>
  </mounting-portal>
</template>
