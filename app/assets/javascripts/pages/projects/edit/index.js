/* eslint-disable no-new */
import UsersSelect from '~/users_select';
import UserCallout from '~/user_callout';
import groupsSelect from '~/groups_select';
import initSettingsPanels from '~/settings_panels';
import setupProjectEdit from '~/project_edit';
import ProjectNew from '../shared/project_new';
import projectAvatar from '../shared/project_avatar';
import initProjectPermissionsSettings from '../shared/permissions';

// EE imports
import ApproversSelect from 'ee/approvers_select'; // eslint-disable-line import/first

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

  // EE imports
  new ApproversSelect(); // eslint-disable-line no-new
};
