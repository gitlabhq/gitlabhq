/* eslint-disable no-new */

import '~/pages/projects/edit';
import UsersSelect from '~/users_select';
import UserCallout from '~/user_callout';
import groupsSelect from '~/groups_select';
import ApproversSelect from 'ee/approvers_select';
import initApproversCheckbox from 'ee/approvers_checkbox';
import initServiceDesk from 'ee/projects/settings_service_desk';

document.addEventListener('DOMContentLoaded', () => {
  new UsersSelect();
  groupsSelect();

  new UserCallout({ className: 'js-service-desk-callout' });
  new UserCallout({ className: 'js-mr-approval-callout' });
  new ApproversSelect();
  initApproversCheckbox();
  initServiceDesk();
});
