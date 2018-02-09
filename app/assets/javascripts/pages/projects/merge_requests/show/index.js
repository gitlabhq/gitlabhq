import MergeRequest from '~/merge_request';
import ZenMode from '~/zen_mode';
import initNotes from '~/init_notes';
import initIssuableSidebar from '~/init_issuable_sidebar';
import ShortcutsIssuable from '~/shortcuts_issuable';
import Diff from '~/diff';
import { handleLocationHash } from '~/lib/utils/common_utils';

export default () => {
  new ZenMode(); // eslint-disable-line no-new
  initIssuableSidebar(); // eslint-disable-line no-new

  const mrShowNode = document.querySelector('.merge-request');

  window.mergeRequest = new MergeRequest({
    action: mrShowNode.dataset.mrAction,
  });

  new Diff(); // eslint-disable-line no-new
  initNotes();
  new ShortcutsIssuable(true); // eslint-disable-line no-new
  handleLocationHash();
};
