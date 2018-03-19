import ZenMode from '~/zen_mode';
import initIssuableSidebar from '~/init_issuable_sidebar';
import ShortcutsIssuable from '~/shortcuts_issuable';
import { handleLocationHash } from '~/lib/utils/common_utils';
import howToMerge from '~/how_to_merge';
import initPipelines from '~/commit/pipelines/pipelines_bundle';
import initWidget from '../../../vue_merge_request_widget';

export default function() {
  new ZenMode(); // eslint-disable-line no-new
  initIssuableSidebar();
  initPipelines();
  new ShortcutsIssuable(true); // eslint-disable-line no-new
  handleLocationHash();
  howToMerge();
  initWidget();
}
