import ZenMode from '~/zen_mode';
import initIssuableSidebar from '~/init_issuable_sidebar';
import ShortcutsIssuable from '~/behaviors/shortcuts/shortcuts_issuable';
import { handleLocationHash } from '~/lib/utils/common_utils';
import howToMerge from '~/how_to_merge';
import initPipelines from '~/commit/pipelines/pipelines_bundle';
import initVueIssuableSidebarApp from '~/issuable_sidebar/sidebar_bundle';
import initSourcegraph from '~/sourcegraph';
import initWidget from '../../../vue_merge_request_widget';

export default function() {
  new ZenMode(); // eslint-disable-line no-new
  if (gon.features && gon.features.vueIssuableSidebar) {
    initVueIssuableSidebarApp();
  } else {
    initIssuableSidebar();
  }
  initPipelines();
  new ShortcutsIssuable(true); // eslint-disable-line no-new
  handleLocationHash();
  howToMerge();
  initWidget();
  initSourcegraph();
}
