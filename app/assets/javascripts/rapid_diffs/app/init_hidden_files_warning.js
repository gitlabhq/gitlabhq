import Vue from 'vue';
import { mapState } from 'pinia';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { pinia } from '~/pinia/instance';
import HiddenFilesWarning from '~/diffs/components/hidden_files_warning.vue';

export async function initHiddenFilesWarning() {
  const el = document.querySelector('[data-hidden-files-warning]');

  // eslint-disable-next-line no-new
  new Vue({
    el,
    pinia,
    computed: {
      ...mapState(useDiffsView, ['overflow', 'totalFilesCount']),
    },
    render(h) {
      if (!this.overflow) return null;

      return h(HiddenFilesWarning, {
        props: {
          total: this.totalFilesCount,
          visible: this.overflow?.visibleCount,
          plainDiffPath: this.overflow?.diffPath,
          emailPatchPath: this.overflow?.emailPath,
        },
      });
    },
  });
}
