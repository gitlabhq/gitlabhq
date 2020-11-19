/* eslint-disable no-new */

import { getPagePath, getDashPath } from '~/lib/utils/common_utils';
import { ACTIVE_TAB_SHARED, ACTIVE_TAB_ARCHIVED } from '~/groups/constants';
import notificationsDropdown from '~/notifications_dropdown';
import NotificationsForm from '~/notifications_form';
import ProjectsList from '~/projects_list';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import GroupTabs from './group_tabs';
import initInviteMembersBanner from '~/groups/init_invite_members_banner';

export default function initGroupDetails(actionName = 'show') {
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

  initInviteMembersBanner();
}
