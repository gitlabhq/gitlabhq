import { initWorkItemsRoot } from '~/work_items';
import { initJiraIssuesImportStatusRoot } from '~/work_items/list';

initWorkItemsRoot({ withTabs: false });
initJiraIssuesImportStatusRoot();
