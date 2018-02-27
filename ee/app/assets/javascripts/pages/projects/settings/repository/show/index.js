import initSettingsPanels from '~/settings_panels';
import initDeployKeys from '~/deploy_keys';
import UsersSelect from '~/users_select';
import UserCallout from '~/user_callout';

import ProtectedBranchCreate from 'ee/protected_branches/protected_branch_create';
import ProtectedBranchEditList from 'ee/protected_branches/protected_branch_edit_list';

document.addEventListener('DOMContentLoaded', () => {
  initDeployKeys();
  initSettingsPanels();
  new ProtectedBranchCreate(); // eslint-disable-line no-new
  new ProtectedBranchEditList(); // eslint-disable-line no-new
  new UsersSelect(); // eslint-disable-line no-new
  new UserCallout(); // eslint-disable-line no-new
});
