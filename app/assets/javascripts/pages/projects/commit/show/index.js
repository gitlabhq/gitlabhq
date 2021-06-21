/* eslint-disable no-new */
import $ from 'jquery';
import loadAwardsHandler from '~/awards_handler';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import Diff from '~/diff';
import createFlash from '~/flash';
import initChangesDropdown from '~/init_changes_dropdown';
import initNotes from '~/init_notes';
import axios from '~/lib/utils/axios_utils';
import { handleLocationHash } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import initCommitActions from '~/projects/commit';
import { initCommitBoxInfo } from '~/projects/commit_box/info';
import syntaxHighlight from '~/syntax_highlight';
import ZenMode from '~/zen_mode';
import '~/sourcegraph/load';

const hasPerfBar = document.querySelector('.with-performance-bar');
const performanceHeight = hasPerfBar ? 35 : 0;
initChangesDropdown(document.querySelector('.navbar-gitlab').offsetHeight + performanceHeight);
new ZenMode();
new ShortcutsNavigation();

initCommitBoxInfo();

initNotes();

const filesContainer = $('.js-diffs-batch');

if (filesContainer.length) {
  const batchPath = filesContainer.data('diffFilesPath');

  axios
    .get(batchPath)
    .then(({ data }) => {
      filesContainer.html($(data));
      syntaxHighlight(filesContainer);
      handleLocationHash();
      new Diff();
    })
    .catch(() => {
      createFlash({ message: __('An error occurred while retrieving diff files') });
    });
} else {
  new Diff();
}
loadAwardsHandler();
initCommitActions();
