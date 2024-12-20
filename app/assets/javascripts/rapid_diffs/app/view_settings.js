import Vue from 'vue';
import { mapState, mapActions } from 'pinia';
import SettingsDropdown from '~/diffs/components/settings_dropdown.vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';

const initSettingsApp = (el, pinia) => {
  return new Vue({
    el,
    pinia,
    computed: {
      ...mapState(useDiffsView, ['showWhitespace', 'viewType', 'fileByFileMode', 'singleFileMode']),
    },
    methods: {
      ...mapActions(useDiffsView, ['updateViewType', 'updateShowWhitespace']),
    },
    render(h) {
      return h(SettingsDropdown, {
        props: {
          showWhitespace: this.showWhitespace,
          diffViewType: this.viewType,
          viewDiffsFileByFile: this.singleFileMode,
        },
        on: {
          updateDiffViewType: this.updateViewType,
          toggleWhitespace: this.updateShowWhitespace,
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
  return initSettingsApp(target, pinia);
};
