/* eslint-disable no-new */

import ProtectedTagCreate from '~/protected_tags/protected_tag_create';
import ProtectedTagEditList from '~/protected_tags/protected_tag_edit_list';
import initSettingsPanels from '~/settings_panels';
import initDeployKeys from '~/deploy_keys';
import ProtectedBranchCreate from '~/protected_branches/protected_branch_create';
import ProtectedBranchEditList from '~/protected_branches/protected_branch_edit_list';
import DueDateSelectors from '~/due_date_select';
import fileUpload from '~/lib/utils/file_upload';

export default () => {
  new ProtectedTagCreate();
  new ProtectedTagEditList();
  initDeployKeys();
  initSettingsPanels();
  new ProtectedBranchCreate({ hasLicense: false });
  new ProtectedBranchEditList();
  new DueDateSelectors();
  fileUpload('.js-choose-file', '.js-object-map-input');
};
