/* eslint-disable no-new */
import UsersSelect from '~/users_select';
import UserCallout from '~/user_callout';
import initSettingsPanels from '~/settings_panels';
import initDeployKeys from '~/deploy_keys';
import ProtectedTagCreate from 'ee/protected_tags/protected_tag_create';
import ProtectedTagEditList from 'ee/protected_tags/protected_tag_edit_list';

document.addEventListener('DOMContentLoaded', () => {
  new UsersSelect();
  new UserCallout();
  new ProtectedTagCreate();
  new ProtectedTagEditList();
  initDeployKeys();
  initSettingsPanels();
});
