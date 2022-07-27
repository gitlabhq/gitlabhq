import { initShow } from '~/issues';
import { store } from '~/notes/stores';
import { initRelatedIssues } from '~/related_issues';
import initSidebarBundle from '~/sidebar/sidebar_bundle';
import initWorkItemLinks from '~/work_items/components/work_item_links';

initShow();
initSidebarBundle(store);
initRelatedIssues();
initWorkItemLinks();
