import initIssuableSidebar from '~/init_issuable_sidebar';
import Issue from '~/issue';
import ShortcutsIssuable from '~/behaviors/shortcuts/shortcuts_issuable';
import ZenMode from '~/zen_mode';
import '~/notes/index';
import initIssueableApp from '~/issue_show';
import initSentryErrorStackTraceApp from '~/sentry_error_stack_trace';
import initRelatedMergeRequestsApp from '~/related_merge_requests';
import initVueIssuableSidebarApp from '~/issuable_sidebar/sidebar_bundle';

export default function() {
  initIssueableApp();
  initSentryErrorStackTraceApp();
  initRelatedMergeRequestsApp();

  // .js-design-management is currently EE-only.
  // This will be moved to CE as part of https://gitlab.com/gitlab-org/gitlab/-/issues/212566#frontend
  // at which point this conditional can be removed.
  if (document.querySelector('.js-design-management')) {
    import(/* webpackChunkName: 'design_management' */ '~/design_management')
      .then(module => module.default())
      .catch(() => {});
  }

  new Issue(); // eslint-disable-line no-new
  new ShortcutsIssuable(); // eslint-disable-line no-new
  new ZenMode(); // eslint-disable-line no-new
  if (gon.features && gon.features.vueIssuableSidebar) {
    initVueIssuableSidebarApp();
  } else {
    initIssuableSidebar();
  }
}
