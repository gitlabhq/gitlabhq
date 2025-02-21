<script>
// eslint-disable-next-line no-restricted-imports
import { mapMutations } from 'vuex';
import DiffsFileTree from '~/diffs/components/diffs_file_tree.vue';
import * as types from '~/diffs/store/mutation_types';
import { DIFF_FILE_MOUNTED } from '~/rapid_diffs/dom_events';

export default {
  name: 'FileBrowser',
  components: {
    DiffsFileTree,
  },
  props: {
    loadedFiles: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      visible: true,
      currentLoadedFiles: { ...this.loadedFiles },
    };
  },
  created() {
    document.addEventListener(DIFF_FILE_MOUNTED, this.addLoadedFile);
  },
  beforeDestroy() {
    document.removeEventListener(DIFF_FILE_MOUNTED, this.addLoadedFile);
  },
  methods: {
    ...mapMutations('diffs', {
      setCurrentDiffFile: types.SET_CURRENT_DIFF_FILE,
    }),
    addLoadedFile({ target }) {
      this.currentLoadedFiles = { ...this.currentLoadedFiles, [target.id]: true };
    },
    clickFile(file) {
      this.$emit('clickFile', file);
      this.setCurrentDiffFile(file.fileHash);
    },
  },
};
</script>

<template>
  <diffs-file-tree
    :visible="visible"
    :loaded-files="currentLoadedFiles"
    @toggled="visible = !visible"
    @clickFile="clickFile"
  />
</template>
