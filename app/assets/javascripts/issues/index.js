import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsIssuable from '~/behaviors/shortcuts/shortcuts_issuable';
import { initIssuableSidebar } from '~/issuable';
import Issue from '~/issues/issue';
import { initRelatedMergeRequests } from '~/issues/related_merge_requests';
import { initRelatedIssues } from '~/related_issues';
import { initIssuableApp, initSentryErrorStackTrace } from '~/issues/show';
import initNotesApp from '~/notes';
import { store } from '~/notes/stores';
import initSidebarBundle from '~/sidebar/sidebar_bundle';
import initWorkItemLinks from '~/work_items/components/work_item_links';
import ZenMode from '~/zen_mode';
import initAwardsApp from '~/emoji/awards_app';

export function initShow() {
  new Issue(); // eslint-disable-line no-new
  addShortcutsExtension(ShortcutsIssuable);
  new ZenMode(); // eslint-disable-line no-new

  initAwardsApp(document.getElementById('js-vue-awards-block'));
  initIssuableApp(store);
  initIssuableSidebar();
  initNotesApp();
  initRelatedIssues();
  initRelatedMergeRequests();
  initSentryErrorStackTrace();
  initSidebarBundle();
  initWorkItemLinks();

  import(/* webpackChunkName: 'design_management' */ '~/design_management')
    .then((module) => module.default())
    .catch(() => {});
}
