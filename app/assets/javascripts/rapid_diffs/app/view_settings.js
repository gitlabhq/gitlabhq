import Vue from 'vue';
import { mapState, mapActions } from 'pinia';
import { parseBoolean } from '~/lib/utils/common_utils';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import DiffAppControls from '~/diffs/components/diff_app_controls.vue';
import { DiffFile } from '~/rapid_diffs/diff_file';
import { COLLAPSE_FILE, EXPAND_FILE } from '~/rapid_diffs/events';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';

const collapseAllFiles = () => {
  DiffFile.getAll().forEach((file) => file.trigger(COLLAPSE_FILE));
};

const expandAllFiles = () => {
  DiffFile.getAll().forEach((file) => file.trigger(EXPAND_FILE));
};

const initSettingsApp = (el, pinia) => {
  return new Vue({
    el,
    pinia,
    computed: {
      ...mapState(useDiffsList, ['isLoading', 'isEmpty']),
      ...mapState(useDiffsView, [
        'showWhitespace',
        'viewType',
        'fileByFileMode',
        'singleFileMode',
        'diffsStats',
      ]),
    },
    methods: {
      ...mapActions(useDiffsView, ['updateViewType', 'updateShowWhitespace']),
    },
    render(h) {
      return h(DiffAppControls, {
        props: {
          hasChanges: !this.isEmpty,
          showWhitespace: this.showWhitespace,
          diffViewType: this.viewType,
          viewDiffsFileByFile: this.singleFileMode,
          isLoading: this.isLoading,
          addedLines: this.diffsStats?.addedLines,
          removedLines: this.diffsStats?.removedLines,
          diffsCount: this.diffsStats?.diffsCount,
        },
        on: {
          updateDiffViewType: this.updateViewType,
          toggleWhitespace: this.updateShowWhitespace,
          expandAllFiles,
          collapseAllFiles,
        },
      });
    },
  });
};

export const initViewSettings = ({ pinia, streamUrl }) => {
  const target = document.querySelector('[data-view-settings]');
  const { showWhitespace, diffViewType, updateUserEndpoint } = target.dataset;
  useDiffsView(pinia).$patch({
    showWhitespace: parseBoolean(showWhitespace),
    viewType: diffViewType,
    updateUserEndpoint,
    streamUrl,
  });
  useDiffsList(pinia).fillInLoadedFiles();
  return initSettingsApp(target, pinia);
};
