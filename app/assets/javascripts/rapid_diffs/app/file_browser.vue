<script>
// eslint-disable-next-line no-restricted-imports
import { mapMutations } from 'vuex';
import { mapState } from 'pinia';
import DiffsFileTree from '~/diffs/components/diffs_file_tree.vue';
import * as types from '~/diffs/store/mutation_types';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';

export default {
  name: 'FileBrowser',
  components: {
    DiffsFileTree,
  },
  data() {
    return {
      visible: true,
    };
  },
  computed: {
    ...mapState(useDiffsList, ['loadedFiles']),
  },
  methods: {
    ...mapMutations('diffs', {
      setCurrentDiffFile: types.SET_CURRENT_DIFF_FILE,
    }),
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
    :loaded-files="loadedFiles"
    @toggled="visible = !visible"
    @clickFile="clickFile"
  />
</template>
