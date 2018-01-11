import Diff from '~/diff';
import ZenMode from '~/zen_mode';
import initIssuableSidebar from '~/init_issuable_sidebar';
import initNotes from '~/init_notes';
import MergeRequest from '~/merge_request';
import ShortcutsIssuable from '~/shortcuts_issuable';

export default () => {
  new Diff(); // eslint-disable-line no-new
  new ZenMode(); // eslint-disable-line no-new

  initIssuableSidebar();
  initNotes();

  const mrShowNode = document.querySelector('.merge-request');
  window.mergeRequest = new MergeRequest({ // eslint-disable-line no-new
    action: mrShowNode.dataset.mrAction,
  });

  new ShortcutsIssuable(true); // eslint-disable-line no-new
};
