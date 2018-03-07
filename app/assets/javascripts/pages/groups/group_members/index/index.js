/* eslint-disable no-new */

import memberExpirationDate from '~/member_expiration_date';
import Members from '~/members';
import UsersSelect from '~/users_select';

document.addEventListener('DOMContentLoaded', () => {
  memberExpirationDate();
  new Members();
  new UsersSelect();
});
