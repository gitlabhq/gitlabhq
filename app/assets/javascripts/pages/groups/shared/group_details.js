/* eslint-disable no-new */

import { getPagePath, getDashPath } from '~/lib/utils/common_utils';
import { ACTIVE_TAB_SHARED, ACTIVE_TAB_ARCHIVED } from '~/groups/constants';
import NewGroupChild from '~/groups/new_group_child';
import notificationsDropdown from '~/notifications_dropdown';
import NotificationsForm from '~/notifications_form';
import ProjectsList from '~/projects_list';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import GroupTabs from './group_tabs';
import initNamespaceStorageLimitAlert from '~/namespace_storage_limit_alert';

export default function initGroupDetails(actionName = 'show') {
  const newGroupChildWrapper = document.querySelector('.js-new-project-subgroup');
  const loadableActions = [ACTIVE_TAB_SHARED, ACTIVE_TAB_ARCHIVED];
  const dashPath = getDashPath();
  let action = loadableActions.includes(dashPath) ? dashPath : getPagePath(1);
  if (actionName && action === actionName) {
    action = 'show'; // 'show' resets GroupTabs to default action through base class
  }

  new GroupTabs({ parentEl: '.groups-listing', action });
  new ShortcutsNavigation();
  new NotificationsForm();
  notificationsDropdown();
  new ProjectsList();

  if (newGroupChildWrapper) {
    new NewGroupChild(newGroupChildWrapper);
  }

  initNamespaceStorageLimitAlert();
}
