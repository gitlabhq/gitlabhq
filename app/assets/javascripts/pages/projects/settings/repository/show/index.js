/* eslint-disable no-new */

import ProtectedTagCreate from '~/protected_tags/protected_tag_create';
import ProtectedTagEditList from '~/protected_tags/protected_tag_edit_list';
import initSettingsPanels from '~/settings_panels';

document.addEventListener('DOMContentLoaded', () => {
  new ProtectedTagCreate();
  new ProtectedTagEditList();
  initSettingsPanels();
});
