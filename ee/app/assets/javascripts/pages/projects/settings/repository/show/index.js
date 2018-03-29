/* eslint-disable no-new */
import UsersSelect from '~/users_select';
import UserCallout from '~/user_callout';
import initSettingsPanels from '~/settings_panels';
import initDeployKeys from '~/deploy_keys';
import CEProtectedBranchCreate from '~/protected_branches/protected_branch_create';
import CEProtectedBranchEditList from '~/protected_branches/protected_branch_edit_list';
import CEProtectedTagCreate from '~/protected_tags/protected_tag_create';
import CEProtectedTagEditList from '~/protected_tags/protected_tag_edit_list';
import PushPull from './push_pull';

import ProtectedBranchCreate from 'ee/protected_branches/protected_branch_create';
import ProtectedBranchEditList from 'ee/protected_branches/protected_branch_edit_list';
import ProtectedTagCreate from 'ee/protected_tags/protected_tag_create';
import ProtectedTagEditList from 'ee/protected_tags/protected_tag_edit_list';

document.addEventListener('DOMContentLoaded', () => {
  new UsersSelect();
  new UserCallout();

  initDeployKeys();
  initSettingsPanels();

  if (document.querySelector('.js-protected-refs-for-users')) {
    new ProtectedBranchCreate();
    new ProtectedBranchEditList();

    new ProtectedTagCreate();
    new ProtectedTagEditList();
  } else {
    new CEProtectedBranchCreate();
    new CEProtectedBranchEditList();

    new CEProtectedTagCreate();
    new CEProtectedTagEditList();
  }

  PushPull.init();
});
