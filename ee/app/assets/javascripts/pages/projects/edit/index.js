/* eslint-disable no-new */
import '~/pages/projects/edit';
import UsersSelect from '~/users_select';
import UserCallout from '~/user_callout';
import groupsSelect from '~/groups_select';
import ApproversSelect from 'ee/approvers_select';

export default () => {
  new UsersSelect();
  groupsSelect();

  new UserCallout({ className: 'js-service-desk-callout' });
  new UserCallout({ className: 'js-mr-approval-callout' });
  new ApproversSelect();
};
