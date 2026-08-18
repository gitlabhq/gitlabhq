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
  emits: ['click-file'],
  data() {
    return {
      currentFileHash: '',
    };
  },
  computed: {
    ...mapState(useDiffsView, ['totalFilesCount', 'singleFileMode', 'currentFileIndex']),
    ...mapState(useDiffsList, ['loadedFiles']),
    ...mapState(useFileBrowser, ['fileBrowserVisible', 'flatBlobsList']),
    treeLoadedFiles() {
      return this.singleFileMode ? null : this.loadedFiles;
    },
    currentDiffFileId() {
      let hash = this.currentFileHash;

      if (this.singleFileMode) {
        hash = this.flatBlobsList[this.currentFileIndex]?.fileHash ?? '';
      }

      return hash;
    },
  },
  methods: {
    clickFile(file) {
      this.currentFileHash = file.fileHash;
      this.$emit('click-file', file);
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
    :loaded-files="treeLoadedFiles"
    :total-files-count="totalFilesCount"
    :group-blobs-list-items="groupBlobsListItems"
    :current-diff-file-id="currentDiffFileId"
    :linked-file-path="linkedFilePath"
    @click-file="clickFile"
    @toggle-folder="toggleFolder"
  />
</template>
