/* eslint-disable no-new */

import Members from 'ee_else_ce/members';
import memberExpirationDate from '~/member_expiration_date';
import UsersSelect from '~/users_select';
import groupsSelect from '~/groups_select';

document.addEventListener('DOMContentLoaded', () => {
  memberExpirationDate();
  memberExpirationDate('.js-access-expiration-date-groups');
  new Members();
  groupsSelect();
  new UsersSelect();
});
