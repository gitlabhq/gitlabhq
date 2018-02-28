import initSidebarBundle from '~/sidebar/sidebar_bundle';
import initShow from '../init_merge_request_show';

document.addEventListener('DOMContentLoaded', () => {
<<<<<<< HEAD
  initShow();
  initSidebarBundle();
=======
  new Diff(); // eslint-disable-line no-new
  new ZenMode(); // eslint-disable-line no-new

  initIssuableSidebar();
  initNotes();
  initDiffNotes();
  initPipelines();

  const mrShowNode = document.querySelector('.merge-request');
  window.mergeRequest = new MergeRequest({
    action: mrShowNode.dataset.mrAction,
  });

  new ShortcutsIssuable(true); // eslint-disable-line no-new
  handleLocationHash();
  howToMerge();
  initWidget();
>>>>>>> origin/master
});
