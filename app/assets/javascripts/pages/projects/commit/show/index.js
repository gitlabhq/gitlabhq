/* eslint-disable no-new */
import $ from 'jquery';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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
import { fetchCommitMergeRequests } from '~/commit_merge_requests';
import initCherryPickCommitModal from '~/projects/commit/init_cherry_pick_commit_modal';
import initCommitOptionsDropdown from '~/projects/commit/init_commit_options_dropdown';
import initRevertCommitModal from '~/projects/commit/init_revert_commit_modal';
import initCommitPipelineSummary from '~/projects/commit_box/info/init_commit_pipeline_summary';
import initCommitReferences from '~/projects/commit_box/info/init_commit_references';
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

fetchCommitMergeRequests();
initCommitPipelineSummary();
initCommitReferences();

initDeprecatedNotes();
initReportAbuse();

const loadDiffStats = () => {
  const diffStatsElements = document.querySelectorAll('#js-diff-stats');

  if (diffStatsElements.length) {
    diffStatsElements.forEach((diffStatsEl) => {
      const { addedLines, removedLines, oldSize, newSize, viewerName } = diffStatsEl.dataset;

      initVueApp({
        el: diffStatsEl,
        name: 'DiffStatsRoot',
        component: DiffStats,
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

initRevertCommitModal();
initCherryPickCommitModal();
initCommitOptionsDropdown();

syntaxHighlight([document.querySelector('.files')]);
