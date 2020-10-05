import initRelatedIssues from '~/related_issues';
import initShow from '../../issues/show';

document.addEventListener('DOMContentLoaded', () => {
  initShow();
  initRelatedIssues();
});
