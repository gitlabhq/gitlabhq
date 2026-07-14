import Vue from 'vue';
import { mapState } from 'pinia';
import { pinia } from '~/pinia/instance';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import FindFile from '~/vue_shared/components/file_finder/index.vue';

export function initFileFinder() {
  const el = document.getElementById('js-diff-file-finder');
  if (!el) return null;

  return new Vue({
    el,
    name: 'RapidDiffsFileFinder',
    pinia,
    components: { FindFile },
    data() {
      return {
        visible: false,
      };
    },
    computed: {
      ...mapState(useFileBrowser, ['flatBlobsList', 'isLoadingFileBrowser']),
    },
    methods: {
      toggle(value) {
        this.visible = value;
      },
      openFile(file) {
        const diffFile = DiffFile.findByFileHash(file.fileHash);
        if (diffFile) {
          window.mrTabs?.tabShown('diffs');
          diffFile.selectFile();
        }
      },
    },
    render(h) {
      return h('find-file', {
        props: {
          files: this.flatBlobsList,
          visible: this.visible,
          loading: this.isLoadingFileBrowser,
          showDiffStats: true,
          clearSearchOnClose: false,
        },
        on: {
          toggle: this.toggle,
          click: this.openFile,
        },
        class: ['diff-file-finder'],
      });
    },
  });
}
