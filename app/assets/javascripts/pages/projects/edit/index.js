/* eslint-disable no-new */
import initSettingsPanels from '~/settings_panels';
import setupProjectEdit from '~/project_edit';

import UsersSelect from '~/users_select';
import UserCallout from '~/user_callout';
import groupsSelect from '~/groups_select';

export default () => {
  new UsersSelect();
  groupsSelect();
  setupProjectEdit();
  // Initialize expandable settings panels
  initSettingsPanels();

  new UserCallout({ className: 'js-service-desk-callout' });
  new UserCallout({ className: 'js-mr-approval-callout' });
};
