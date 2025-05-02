<script>
import FileBrowserHeight from '~/diffs/components/file_browser_height.vue';
import TreeList from './components/tree_list.vue';

export const TREE_WIDTH = 320;

export default {
  name: 'FileTreeBrowser',
  components: {
    TreeList,
    FileBrowserHeight,
  },
  data() {
    return {
      treeWidth: TREE_WIDTH,
      isLoading: false,
      totalFilesCount: 0,
    };
  },
};
</script>

<template>
  <div>
    <file-browser-height :style="{ width: `${treeWidth}px` }" class="repository-tree-list">
      <tree-list v-if="!isLoading" class="gl-mr-5 gl-mt-5" :total-files-count="totalFilesCount" />
    </file-browser-height>
  </div>
</template>
