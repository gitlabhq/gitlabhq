import $ from 'jquery';
import IssuableForm from 'ee_else_ce/issuable/issuable_form';
import IssuableLabelSelector from '~/issuable/issuable_label_selector';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsIssuable from '~/behaviors/shortcuts/shortcuts_issuable';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import { initIssuableSidebar } from '~/issuable';
import Issue from '~/issues/issue';
import { initTitleSuggestions, initTypePopover, initTypeSelect } from '~/issues/new';
import { initRelatedMergeRequests } from '~/issues/related_merge_requests';
import { initRelatedIssues } from '~/related_issues';
import { initIssuableApp, initSentryErrorStackTrace } from '~/issues/show';
import LabelsSelect from '~/labels/labels_select';
import initNotesApp from '~/notes';
import { store } from '~/notes/stores';
import { mountMilestoneDropdown } from '~/sidebar/mount_sidebar';
import initSidebarBundle from '~/sidebar/sidebar_bundle';
import initWorkItemLinks from '~/work_items/components/work_item_links';
import ZenMode from '~/zen_mode';
import initAwardsApp from '~/emoji/awards_app';

export function initForm() {
  new IssuableForm($('.issue-form')); // eslint-disable-line no-new
  IssuableLabelSelector();
  new LabelsSelect(); // eslint-disable-line no-new
  addShortcutsExtension(ShortcutsNavigation);

  initTitleSuggestions();
  initTypePopover();
  initTypeSelect();
  mountMilestoneDropdown();
}

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
  initSidebarBundle(store);
  initWorkItemLinks();

  import(/* webpackChunkName: 'design_management' */ '~/design_management')
    .then((module) => module.default())
    .catch(() => {});
}
