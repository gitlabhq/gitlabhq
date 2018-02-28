/* eslint-disable no-new */
import UsersSelect from '~/users_select';
import UserCallout from '~/user_callout';
import initSettingsPanels from '~/settings_panels';
import initDeployKeys from '~/deploy_keys';
import ProtectedTagCreate from 'ee/protected_tags/protected_tag_create';
import ProtectedTagEditList from 'ee/protected_tags/protected_tag_edit_list';
import CEProtectedTagCreate from '~/protected_tags/protected_tag_create';
import CEProtectedTagEditList from '~/protected_tags/protected_tag_edit_list';

document.addEventListener('DOMContentLoaded', () => {
  new UsersSelect();
  new UserCallout();
  if (document.querySelector('.js-protected-refs-for-users')) {
    new ProtectedTagCreate();
    new ProtectedTagEditList();
  } else {
    new CEProtectedTagCreate();
    new CEProtectedTagEditList();
  }
  initDeployKeys();
  initSettingsPanels();
});
