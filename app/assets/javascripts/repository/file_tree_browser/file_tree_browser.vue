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
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    currentRef: {
      type: String,
      required: true,
    },
    refType: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      treeWidth: TREE_WIDTH,
    };
  },
  computed: {
    isProjectOverview() {
      return this.$route.name === 'projectRoot';
    },
  },
};
</script>

<template>
  <file-browser-height
    v-if="!isProjectOverview"
    :style="{ width: `${treeWidth}px` }"
    class="repository-tree-list gl-mt-5"
  >
    <tree-list
      class="gl-mr-5"
      :project-path="projectPath"
      :current-ref="currentRef"
      :ref-type="refType"
    />
  </file-browser-height>
</template>
