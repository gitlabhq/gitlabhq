import groupsSelect from '~/groups_select';
import UserCallout from '~/user_callout';

groupsSelect();

// eslint-disable-next-line no-new
new UserCallout({ className: 'js-mr-approval-callout' });
