/* eslint-disable no-new */

import NewGroupChild from '~/groups/new_group_child';
import notificationsDropdown from '~/notifications_dropdown';
import NotificationsForm from '~/notifications_form';
import ProjectsList from '~/projects_list';
import ShortcutsNavigation from '~/shortcuts_navigation';
import initGroupsList from '~/groups';

document.addEventListener('DOMContentLoaded', () => {
  const newGroupChildWrapper = document.querySelector('.js-new-project-subgroup');
  new ShortcutsNavigation();
  new NotificationsForm();
  notificationsDropdown();
  new ProjectsList();

  if (newGroupChildWrapper) {
    new NewGroupChild(newGroupChildWrapper);
  }

  initGroupsList();
});
