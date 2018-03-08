import MergeRequest from '~/merge_request';
import ZenMode from '~/zen_mode';
import initNotes from '~/init_notes';
import initIssuableSidebar from '~/init_issuable_sidebar';
import initDiffNotes from '~/diff_notes/diff_notes_bundle';
import ShortcutsIssuable from '~/shortcuts_issuable';
import Diff from '~/diff';
import { handleLocationHash } from '~/lib/utils/common_utils';
import howToMerge from '~/how_to_merge';
import initPipelines from '~/commit/pipelines/pipelines_bundle';
import initWidget from '../../../vue_merge_request_widget';

export default function () {
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
}
