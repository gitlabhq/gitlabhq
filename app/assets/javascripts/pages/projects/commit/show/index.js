/* eslint-disable no-new */
import $ from 'jquery';
import Vue from 'vue';
import loadAwardsHandler from '~/awards_handler';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import Diff from '~/diff';
import { createAlert } from '~/alert';
import initDeprecatedNotes from '~/init_deprecated_notes';
import { initDiffStatsDropdown } from '~/init_diff_stats_dropdown';
import axios from '~/lib/utils/axios_utils';
import { handleLocationHash } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import initCommitActions from '~/projects/commit';
import { initCommitBoxInfo } from '~/projects/commit_box/info';
import syntaxHighlight from '~/syntax_highlight';
import ZenMode from '~/zen_mode';
import '~/sourcegraph/load';
import DiffStats from '~/diffs/components/diff_stats.vue';
import { initReportAbuse } from '~/projects/report_abuse';
import * as popovers from '~/popovers';
import { performanceMarkAndMeasure } from '~/performance/utils';
import {
  COMMIT_DIFFS_MARK_START_LOADING,
  COMMIT_DIFFS_MARK_DIFF_FILES_SHOWN,
  COMMIT_DIFFS_MEASURE_LIST_LOADED,
} from '~/performance/constants';

popovers.initPopovers();
initDiffStatsDropdown();
new ZenMode();
addShortcutsExtension(ShortcutsNavigation);

initCommitBoxInfo();

initDeprecatedNotes();
initReportAbuse();

const loadDiffStats = () => {
  const diffStatsElements = document.querySelectorAll('#js-diff-stats');

  if (diffStatsElements.length) {
    diffStatsElements.forEach((diffStatsEl) => {
      const { addedLines, removedLines, oldSize, newSize, viewerName } = diffStatsEl.dataset;

      new Vue({
        el: diffStatsEl,
        render(createElement) {
          return createElement(DiffStats, {
            props: {
              diffFile: {
                old_size: oldSize,
                new_size: newSize,
                viewer: { name: viewerName },
              },
              addedLines: Number(addedLines),
              removedLines: Number(removedLines),
            },
          });
        },
      });
    });
  }
};

const filesContainer = $('.js-diffs-batch');

if (filesContainer.length) {
  const batchPath = filesContainer.data('diffFilesPath');

  window.performance.mark(COMMIT_DIFFS_MARK_START_LOADING);

  axios
    .get(batchPath)
    .then(({ data }) => {
      filesContainer.html($(data));
      syntaxHighlight(filesContainer);
      handleLocationHash();
      new Diff();
      loadDiffStats();
      initReportAbuse();

      // Mark when all diffs are loaded and create measure
      performanceMarkAndMeasure({
        mark: COMMIT_DIFFS_MARK_DIFF_FILES_SHOWN,
        measures: [
          {
            name: COMMIT_DIFFS_MEASURE_LIST_LOADED,
            start: COMMIT_DIFFS_MARK_START_LOADING,
            end: COMMIT_DIFFS_MARK_DIFF_FILES_SHOWN,
          },
        ],
      });
    })
    .catch(() => {
      createAlert({ message: __('An error occurred while retrieving diff files') });
    });
} else {
  new Diff();
  loadDiffStats();
}

loadAwardsHandler();
initCommitActions();

syntaxHighlight([document.querySelector('.files')]);
