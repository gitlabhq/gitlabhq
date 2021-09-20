import { store } from '~/notes/stores';
import initRelatedIssues from '~/related_issues';
import initSidebarBundle from '~/sidebar/sidebar_bundle';
import initShow from '../show';

initShow();
initSidebarBundle(store);
initRelatedIssues();
