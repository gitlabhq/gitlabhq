/* eslint-disable no-new */

import initDatePicker from '~/behaviors/date_picker';
import initDeployKeys from '~/deploy_keys';
import fileUpload from '~/lib/utils/file_upload';
import ProtectedBranchCreate from '~/protected_branches/protected_branch_create';
import ProtectedBranchEditList from '~/protected_branches/protected_branch_edit_list';
import ProtectedTagCreate from '~/protected_tags/protected_tag_create';
import ProtectedTagEditList from '~/protected_tags/protected_tag_edit_list';
import initSettingsPanels from '~/settings_panels';

export default () => {
  new ProtectedTagCreate();
  new ProtectedTagEditList();
  initDeployKeys();
  initSettingsPanels();
  new ProtectedBranchCreate({ hasLicense: false });
  new ProtectedBranchEditList();
  initDatePicker(); // Used for deploy token "expires at" field
  fileUpload('.js-choose-file', '.js-object-map-input');
};
