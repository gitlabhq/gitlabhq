/* eslint-disable no-new */

import Members from 'ee_else_ce/members';
import memberExpirationDate from '~/member_expiration_date';
import UsersSelect from '~/users_select';

document.addEventListener('DOMContentLoaded', () => {
  memberExpirationDate();
  new Members();
  new UsersSelect();
});
