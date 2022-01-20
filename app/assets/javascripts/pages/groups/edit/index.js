import { GROUP_BADGE } from '~/badges/constants';
import dirtySubmitFactory from '~/dirty_submit/dirty_submit_factory';
import initFilePickers from '~/file_pickers';
import TransferDropdown from '~/groups/transfer_dropdown';
import setupTransferEdit from '~/groups/transfer_edit';
import groupsSelect from '~/groups_select';
import { initCascadingSettingsLockPopovers } from '~/namespaces/cascading_settings';
import mountBadgeSettings from '~/pages/shared/mount_badge_settings';
import projectSelect from '~/project_select';
import initSearchSettings from '~/search_settings';
import initSettingsPanels from '~/settings_panels';
import initConfirmDanger from '~/init_confirm_danger';

document.addEventListener('DOMContentLoaded', () => {
  initFilePickers();
  initConfirmDanger();
  initSettingsPanels();
  dirtySubmitFactory(
    document.querySelectorAll('.js-general-settings-form, .js-general-permissions-form'),
  );
  mountBadgeSettings(GROUP_BADGE);
  setupTransferEdit('.js-group-transfer-form', '#new_parent_group_id');

  // Initialize Subgroups selector
  groupsSelect();

  projectSelect();

  initSearchSettings();
  initCascadingSettingsLockPopovers();

  return new TransferDropdown();
});
