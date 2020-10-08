import initSidebarBundle from '~/sidebar/sidebar_bundle';
import initRelatedIssues from '~/related_issues';
import initShow from '../show';

initShow();
if (gon.features && !gon.features.vueIssuableSidebar) {
  initSidebarBundle();
}
initRelatedIssues();
