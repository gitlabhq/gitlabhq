import leaveByUrl, { NAMESPACE_TYPES } from '~/namespaces/leave_by_url';
import { initGroupsShowApp } from '~/groups/show';
import { initGroupReadme } from '~/groups/init_group_readme';
import initReadMore from '~/read_more';
import { initGroupActions } from '~/groups/show/actions';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import initNotificationsDropdown from '~/notifications';

addShortcutsExtension(ShortcutsNavigation);
initNotificationsDropdown();
initGroupsShowApp();
initReadMore();
initGroupReadme();
initGroupActions();
leaveByUrl(NAMESPACE_TYPES.GROUP);
