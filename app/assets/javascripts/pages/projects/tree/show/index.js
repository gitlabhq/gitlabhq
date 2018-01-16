import initPathLocks from 'ee/path_locks';
import TreeView from '../../../../tree';
import ShortcutsNavigation from '../../../../shortcuts_navigation';
import BlobViewer from '../../../../blob/viewer';
import NewCommitForm from '../../../../new_commit_form';
import { ajaxGet } from '../../../../lib/utils/common_utils';

export default () => {
  new ShortcutsNavigation(); // eslint-disable-line no-new
  new TreeView(); // eslint-disable-line no-new
  new BlobViewer(); // eslint-disable-line no-new
  new NewCommitForm($('.js-create-dir-form')); // eslint-disable-line no-new
  $('#tree-slider').waitForImages(() =>
    ajaxGet(document.querySelector('.js-tree-content').dataset.logsPath));

  if (document.querySelector('.js-tree-content').dataset.pathLocksAvailable === 'true') {
    initPathLocks(
      document.querySelector('.js-tree-content').dataset.pathLocksToggle,
      document.querySelector('.js-tree-content').dataset.pathLocksPath,
    );
  }
};
