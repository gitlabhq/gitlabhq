/* eslint-disable no-new */

import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import { ACTIVE_TAB_SHARED, ACTIVE_TAB_ARCHIVED } from '~/groups/constants';
import initInviteMembersBanner from '~/groups/init_invite_members_banner';
import initInviteMembersModal from '~/invite_members/init_invite_members_modal';
import { getPagePath, getDashPath } from '~/lib/utils/common_utils';
import initNotificationsDropdown from '~/notifications';
import ProjectsList from '~/projects_list';
import GroupTabs from './group_tabs';

export default function initGroupDetails(actionName = 'show') {
  const loadableActions = [ACTIVE_TAB_SHARED, ACTIVE_TAB_ARCHIVED];
  const dashPath = getDashPath();
  let action = loadableActions.includes(dashPath) ? dashPath : getPagePath(1);
  if (actionName && action === actionName) {
    action = 'show'; // 'show' resets GroupTabs to default action through base class
  }

  new GroupTabs({ parentEl: '.groups-listing', action });
  new ShortcutsNavigation();

  initNotificationsDropdown();

  new ProjectsList();

  initInviteMembersBanner();
  initInviteMembersModal();
}
