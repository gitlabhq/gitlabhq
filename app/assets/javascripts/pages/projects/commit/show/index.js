/* eslint-disable no-new */

import $ from 'jquery';
import Diff from '~/diff';
import ZenMode from '~/zen_mode';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import initNotes from '~/init_notes';
import initChangesDropdown from '~/init_changes_dropdown';
import '~/sourcegraph/load';
import { handleLocationHash } from '~/lib/utils/common_utils';
import axios from '~/lib/utils/axios_utils';
import syntaxHighlight from '~/syntax_highlight';
import flash from '~/flash';
import { __ } from '~/locale';
import loadAwardsHandler from '~/awards_handler';
import { initCommitBoxInfo } from '~/projects/commit_box/info';

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
      filesContainer.html($(data.html));
      syntaxHighlight(filesContainer);
      handleLocationHash();
      new Diff();
    })
    .catch(() => {
      flash({ message: __('An error occurred while retrieving diff files') });
    });
} else {
  new Diff();
}
loadAwardsHandler();
