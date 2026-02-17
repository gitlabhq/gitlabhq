<script>
import { mapState } from 'pinia';
import DiffsFileTree from '~/diffs/components/diffs_file_tree.vue';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';

export default {
  name: 'FileBrowser',
  components: {
    DiffsFileTree,
  },
  props: {
    groupBlobsListItems: {
      type: Boolean,
      required: false,
      default: true,
    },
    linkedFilePath: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      currentFileHash: '',
    };
  },
  computed: {
    ...mapState(useDiffsView, ['totalFilesCount']),
    ...mapState(useDiffsList, ['loadedFiles']),
    ...mapState(useFileBrowser, ['fileBrowserVisible']),
  },
  methods: {
    clickFile(file) {
      this.currentFileHash = file.fileHash;
      this.$emit('clickFile', file);
    },
    toggleFolder(path) {
      useFileBrowser().toggleTreeOpen(path);
    },
  },
};
</script>

<template>
  <diffs-file-tree
    v-if="fileBrowserVisible"
    floating-resize
    :loaded-files="loadedFiles"
    :total-files-count="totalFilesCount"
    :group-blobs-list-items="groupBlobsListItems"
    :current-diff-file-id="currentFileHash"
    :linked-file-path="linkedFilePath"
    @clickFile="clickFile"
    @toggleFolder="toggleFolder"
  />
</template>
