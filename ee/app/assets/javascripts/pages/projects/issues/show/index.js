import initShow from '~/pages/projects/issues/show';
import initSidebarBundle from 'ee/sidebar/sidebar_bundle';
import initRelatedIssues from 'ee/related_issues';

document.addEventListener('DOMContentLoaded', () => {
  initShow();
  initSidebarBundle();
  initRelatedIssues();
});
