import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import { mountIssuesListApp, mountJiraIssuesListApp } from '~/issues/list';
import { initWorkItemsRoot } from '~/work_items';

mountIssuesListApp();
mountJiraIssuesListApp();
addShortcutsExtension(ShortcutsNavigation);

initWorkItemsRoot();
