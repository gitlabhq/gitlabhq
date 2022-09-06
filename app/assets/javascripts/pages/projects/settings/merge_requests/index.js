import groupsSelect from '~/groups_select';
import UserCallout from '~/user_callout';
import UsersSelect from '~/users_select';

// eslint-disable-next-line no-new
new UsersSelect();
groupsSelect();

// eslint-disable-next-line no-new
new UserCallout({ className: 'js-mr-approval-callout' });
