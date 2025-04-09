<script>
import { mapState } from 'pinia';
import DiffsFileTree from '~/diffs/components/diffs_file_tree.vue';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { useFileBrowser } from '~/diffs/stores/file_browser';

export default {
  name: 'FileBrowser',
  components: {
    DiffsFileTree,
  },
  computed: {
    ...mapState(useDiffsList, ['loadedFiles']),
    ...mapState(useFileBrowser, ['fileBrowserVisible']),
  },
  methods: {
    clickFile(file) {
      this.$emit('clickFile', file);
    },
  },
};
</script>

<template>
  <diffs-file-tree
    v-if="fileBrowserVisible"
    floating-resize
    :loaded-files="loadedFiles"
    @clickFile="clickFile"
  />
</template>
