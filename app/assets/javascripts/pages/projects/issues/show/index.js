import { initShow } from '~/issues';
import { store } from '~/notes/stores';
import initRelatedIssues from '~/related_issues';
import initSidebarBundle from '~/sidebar/sidebar_bundle';

initShow();
initSidebarBundle(store);
initRelatedIssues();
