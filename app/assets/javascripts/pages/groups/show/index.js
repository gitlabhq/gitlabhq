/* eslint-disable no-new */

import { getPagePath } from '~/lib/utils/common_utils';
import { ACTIVE_TAB_SHARED, ACTIVE_TAB_ARCHIVED } from '~/groups/constants';
import NewGroupChild from '~/groups/new_group_child';
import notificationsDropdown from '~/notifications_dropdown';
import NotificationsForm from '~/notifications_form';
import ProjectsList from '~/projects_list';
import ShortcutsNavigation from '~/shortcuts_navigation';
import GroupTabs from './group_tabs';

document.addEventListener('DOMContentLoaded', () => {
  const newGroupChildWrapper = document.querySelector('.js-new-project-subgroup');
  const loadableActions = [ACTIVE_TAB_SHARED, ACTIVE_TAB_ARCHIVED];
  const paths = window.location.pathname.split('/');
  const subpath = paths[paths.length - 1];
  const action = loadableActions.includes(subpath) ? subpath : getPagePath(1);

  new GroupTabs({ parentEl: '.groups-listing', action });
  new ShortcutsNavigation();
  new NotificationsForm();
  notificationsDropdown();
  new ProjectsList();

  if (newGroupChildWrapper) {
    new NewGroupChild(newGroupChildWrapper);
  }
});
