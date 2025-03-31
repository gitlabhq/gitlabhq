import { defineStore } from 'pinia';
import { historyPushState, setCookie } from '~/lib/utils/common_utils';
import {
  DIFF_VIEW_COOKIE_NAME,
  INLINE_DIFF_VIEW_TYPE,
  TRACKING_CLICK_DIFF_VIEW_SETTING,
  TRACKING_DIFF_VIEW_INLINE,
  TRACKING_DIFF_VIEW_PARALLEL,
} from '~/diffs/constants';
import { queueRedisHllEvents } from '~/diffs/utils/queue_events';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import axios from '~/lib/utils/axios_utils';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import store from '~/mr_notes/stores';

export const useDiffsView = defineStore('diffsView', {
  state() {
    return {
      viewType: INLINE_DIFF_VIEW_TYPE,
      showWhitespace: true,
      singleFileMode: false,
      updateUserEndpoint: undefined,
      streamUrl: undefined,
      metadataEndpoint: undefined,
      diffStats: null,
    };
  },
  actions: {
    async loadMetadata() {
      // TODO: refactor this to our own Pinia stores
      store.state.diffs.endpointMetadata = this.metadataEndpoint;
      store.state.diffs.diffViewType = this.viewType;
      store.state.diffs.showWhitespace = this.showWhitespace;
      await store.dispatch('diffs/fetchDiffFilesMeta');
      this.diffStats = {
        addedLines: store.state.diffs.addedLines,
        removedLines: store.state.diffs.removedLines,
        size: store.state.diffs.size,
        realSize: store.state.diffs.realSize,
        plainDiffPath: store.state.diffs.plainDiffPath,
        emailPatchPath: store.state.diffs.emailPatchPath,
        renderOverflowWarning: store.state.diffs.renderOverflowWarning,
        // we will be using a number for that after refactoring
        diffsCount: parseInt(store.state.diffs.realSize, 10),
      };
    },
    updateDiffView() {
      if (this.singleFileMode) {
        // TODO: implement single file mode
        return;
      }
      useDiffsList().reloadDiffs(mergeUrlParams(this.requestParams, this.streamUrl));
    },
    updateViewType(view) {
      this.viewType = view;
      setCookie(DIFF_VIEW_COOKIE_NAME, view);
      queueRedisHllEvents([
        TRACKING_CLICK_DIFF_VIEW_SETTING,
        view === INLINE_DIFF_VIEW_TYPE ? TRACKING_DIFF_VIEW_INLINE : TRACKING_DIFF_VIEW_PARALLEL,
      ]);
      historyPushState(mergeUrlParams({ view }, window.location.href));
      this.updateDiffView();
    },
    updateShowWhitespace(value) {
      this.showWhitespace = value;
      // whitespace setting persists only for authenticated users
      if (this.updateUserEndpoint) {
        // we don't have to wait for the setting to be saved since whitespace param is passed explicitly
        axios.put(this.updateUserEndpoint, { show_whitespace_in_diffs: value });
      }
      this.loadMetadata();
      this.updateDiffView();
    },
  },
  getters: {
    requestParams() {
      // w: '1' means ignore whitespace, app/helpers/diff_helper.rb#hide_whitespace?
      return { view: this.viewType, w: this.showWhitespace ? '0' : '1' };
    },
  },
});
