/* eslint-disable no-new */

import ProtectedTagCreate from '~/protected_tags/protected_tag_create';
import ProtectedTagEditList from '~/protected_tags/protected_tag_edit_list';
import initSettingsPanels from '~/settings_panels';
import initDeployKeys from '~/deploy_keys';
import ProtectedBranchCreate from '~/protected_branches/protected_branch_create';
import ProtectedBranchEditList from '~/protected_branches/protected_branch_edit_list';
import DueDateSelectors from '~/due_date_select';

export default () => {
  new ProtectedTagCreate();
  new ProtectedTagEditList();
  initDeployKeys();
  initSettingsPanels();
  new ProtectedBranchCreate(); // eslint-disable-line no-new
  new ProtectedBranchEditList(); // eslint-disable-line no-new
  new DueDateSelectors();
};
