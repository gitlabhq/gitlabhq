/* eslint-disable no-new */
import initSettingsPanels from '~/settings_panels';
import setupProjectEdit from '~/project_edit';
import ProjectNew from '../shared/project_new';
import projectAvatar from '../shared/project_avatar';
import initProjectPermissionsSettings from '../shared/permissions';

import UsersSelect from '~/users_select';
import UserCallout from '~/user_callout';
import groupsSelect from '~/groups_select';

export default () => {
  new ProjectNew(); // eslint-disable-line no-new
  new UsersSelect();
  groupsSelect();
  setupProjectEdit();
  // Initialize expandable settings panels
  initSettingsPanels();
  projectAvatar();
  initProjectPermissionsSettings();

  new UserCallout({ className: 'js-service-desk-callout' });
  new UserCallout({ className: 'js-mr-approval-callout' });
};
