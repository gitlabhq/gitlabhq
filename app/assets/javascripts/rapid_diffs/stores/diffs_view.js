import { defineStore } from 'pinia';
import { historyPushState, setCookie } from '~/lib/utils/common_utils';
import {
  DIFF_VIEW_COOKIE_NAME,
  INLINE_DIFF_VIEW_TYPE,
  TRACKING_CLICK_DIFF_VIEW_SETTING,
  TRACKING_CLICK_SINGLE_FILE_SETTING,
  TRACKING_DIFF_VIEW_INLINE,
  TRACKING_DIFF_VIEW_PARALLEL,
  TRACKING_MULTIPLE_FILES_MODE,
  TRACKING_SINGLE_FILE_MODE,
} from '~/diffs/constants';
import { queueRedisHllEvents } from '~/diffs/utils/queue_events';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import axios from '~/lib/utils/axios_utils';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { useFileBrowser } from '~/diffs/stores/file_browser';

export const useDiffsView = defineStore('diffsView', {
  state() {
    return {
      viewType: INLINE_DIFF_VIEW_TYPE,
      showWhitespace: true,
      fileByFileMode: false,
      singleFileMode: false,
      currentFileIndex: 0,
      updateUserEndpoint: undefined,
      diffFileEndpoint: undefined,
      streamUrl: undefined,
      diffsStatsEndpoint: undefined,
      diffsStats: null,
      overflow: null,
    };
  },
  actions: {
    async loadDiffsStats() {
      const { data } = await axios.get(this.diffsStatsEndpoint);
      const {
        added_lines: addedLines,
        removed_lines: removedLines,
        diffs_count: diffsCount,
        real_size: realSize,
      } = data.diffs_stats;
      this.diffsStats = {
        addedLines,
        removedLines,
        diffsCount,
        realSize,
      };
      if (data.overflow) {
        const {
          visible_count: visibleCount,
          email_path: emailPath,
          diff_path: diffPath,
        } = data.overflow || {};
        this.overflow = {
          visibleCount,
          emailPath,
          diffPath,
        };
      } else {
        this.overflow = null;
      }
    },
    updateDiffView() {
      if (this.singleFileMode) {
        this.loadCurrentFile();
        return;
      }
      useDiffsList().reloadDiffs(mergeUrlParams(this.requestParams, this.streamUrl));
    },
    loadCurrentFile() {
      const file = useFileBrowser().flatBlobsList[this.currentFileIndex];
      if (!file) return;
      useDiffsList().loadSingleFile({
        endpoint: this.diffFileEndpoint,
        oldPath: file.filePaths.old,
        newPath: file.filePaths.new,
        viewType: this.viewType,
        showWhitespace: this.showWhitespace,
      });
    },
    goToFile(index) {
      const { flatBlobsList } = useFileBrowser();
      if (index < 0 || index >= flatBlobsList.length) return;
      this.currentFileIndex = index;
      this.loadCurrentFile();
    },
    goToNextFile() {
      this.goToFile(this.currentFileIndex + 1);
    },
    resolveInitialFileIndex({ linkedFileData } = {}) {
      if (!linkedFileData) return;

      const { flatBlobsList } = useFileBrowser();
      const index = flatBlobsList.findIndex(
        (entry) =>
          entry.filePaths.old === linkedFileData.oldPath &&
          entry.filePaths.new === linkedFileData.newPath,
      );

      if (index >= 0) {
        this.currentFileIndex = index;
      }
    },
    goToPrevFile() {
      this.goToFile(this.currentFileIndex - 1);
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
    toggleFileByFile(value) {
      this.fileByFileMode = value;
      this.singleFileMode = value;
      queueRedisHllEvents([
        TRACKING_CLICK_SINGLE_FILE_SETTING,
        value ? TRACKING_SINGLE_FILE_MODE : TRACKING_MULTIPLE_FILES_MODE,
      ]);
      if (this.updateUserEndpoint) {
        axios.put(this.updateUserEndpoint, { view_diffs_file_by_file: value });
      }
      this.updateDiffView();
    },
    updateShowWhitespace(value) {
      this.showWhitespace = value;
      // whitespace setting persists only for authenticated users
      if (this.updateUserEndpoint) {
        // we don't have to wait for the setting to be saved since whitespace param is passed explicitly
        axios.put(this.updateUserEndpoint, { show_whitespace_in_diffs: value });
      }
      this.updateDiffView();
    },
  },
  getters: {
    requestParams() {
      // w: '1' means ignore whitespace, app/helpers/diff_helper.rb#hide_whitespace?
      return { view: this.viewType, w: this.showWhitespace ? '0' : '1' };
    },
    totalFilesCount() {
      return this.diffsStats?.realSize ?? this.diffsStats?.diffsCount;
    },
    currentFileNumber() {
      return this.currentFileIndex + 1;
    },
    hasNextFile() {
      return this.currentFileIndex < useFileBrowser().flatBlobsList.length - 1;
    },
    hasPrevFile() {
      return this.currentFileIndex > 0;
    },
  },
});
