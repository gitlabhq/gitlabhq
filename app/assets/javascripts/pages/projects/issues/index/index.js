import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import { mountIssuesListApp, mountJiraIssuesListApp } from '~/issues/list';

mountIssuesListApp();
mountJiraIssuesListApp();
addShortcutsExtension(ShortcutsNavigation);
