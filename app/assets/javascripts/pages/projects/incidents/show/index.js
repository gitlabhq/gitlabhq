import initSidebarBundle from '~/sidebar/sidebar_bundle';
import initRelatedIssues from '~/related_issues';
import initShow from '../../issues/show';

document.addEventListener('DOMContentLoaded', () => {
  initShow();
  if (!gon.features?.vueIssuableSidebar) {
    initSidebarBundle();
  }
  initRelatedIssues();
});
