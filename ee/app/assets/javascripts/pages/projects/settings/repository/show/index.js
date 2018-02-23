/* eslint-disable no-new */

import '~/pages/projects/settings/repository/show/index';
import UsersSelect from '~/users_select';
import UserCallout from '~/user_callout';
import ProtectedTagCreate from 'ee/protected_tags/protected_tag_create';
import ProtectedTagEditList from 'ee/protected_tags/protected_tag_edit_list';

document.addEventListener('DOMContentLoaded', () => {
  new UsersSelect();
  new UserCallout();
  new ProtectedTagCreate();
  new ProtectedTagEditList();
});
