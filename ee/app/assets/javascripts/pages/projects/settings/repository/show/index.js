import initSettingsPanels from '~/settings_panels';
import initDeployKeys from '~/deploy_keys';
import UsersSelect from '~/users_select';
import UserCallout from '~/user_callout';
import CEprotectedBranchCreate from '~/protected_branches/protected_branch_create';
import CEprotectedBranchEditList from '~/protected_branches/protected_branch_edit_list';

import ProtectedBranchCreate from 'ee/protected_branches/protected_branch_create';
import ProtectedBranchEditList from 'ee/protected_branches/protected_branch_edit_list';

document.addEventListener('DOMContentLoaded', () => {
  initDeployKeys();
  initSettingsPanels();
  new UsersSelect(); // eslint-disable-line no-new
  new UserCallout(); // eslint-disable-line no-new

  if (document.querySelector('.js-protected-refs-for-users')) {
    new ProtectedBranchCreate(); // eslint-disable-line no-new
    new ProtectedBranchEditList(); // eslint-disable-line no-new
  } else {
    new CEprotectedBranchCreate(); // eslint-disable-line no-new
    new CEprotectedBranchEditList(); // eslint-disable-line no-new
  }
});
