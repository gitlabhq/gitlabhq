import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import { mountIssuesListApp, mountJiraIssuesListApp } from '~/issues/list';

mountIssuesListApp();
mountJiraIssuesListApp();
new ShortcutsNavigation(); // eslint-disable-line no-new
