/* eslint-disable no-new */

import $ from 'jquery';
import Diff from '~/diff';
import ZenMode from '~/zen_mode';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import MiniPipelineGraph from '~/mini_pipeline_graph_dropdown';
import initNotes from '~/init_notes';
import initChangesDropdown from '~/init_changes_dropdown';
import initDiffNotes from '~/diff_notes/diff_notes_bundle';
import { fetchCommitMergeRequests } from '~/commit_merge_requests';
import '~/sourcegraph/load';

document.addEventListener('DOMContentLoaded', () => {
  const hasPerfBar = document.querySelector('.with-performance-bar');
  const performanceHeight = hasPerfBar ? 35 : 0;
  new Diff();
  new ZenMode();
  new ShortcutsNavigation();
  new MiniPipelineGraph({
    container: '.js-commit-pipeline-graph',
  }).bindEvents();
  initNotes();
  initChangesDropdown(document.querySelector('.navbar-gitlab').offsetHeight + performanceHeight);
  // eslint-disable-next-line no-jquery/no-load
  $('.commit-info.branches').load(document.querySelector('.js-commit-box').dataset.commitPath);
  fetchCommitMergeRequests();
  initDiffNotes();
});
