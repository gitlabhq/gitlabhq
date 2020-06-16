import initFilePickers from '~/file_pickers';
import TransferDropdown from '~/groups/transfer_dropdown';
import initConfirmDangerModal from '~/confirm_danger_modal';
import initSettingsPanels from '~/settings_panels';
import setupTransferEdit from '~/transfer_edit';
import dirtySubmitFactory from '~/dirty_submit/dirty_submit_factory';
import mountBadgeSettings from '~/pages/shared/mount_badge_settings';
import { GROUP_BADGE } from '~/badges/constants';
import groupsSelect from '~/groups_select';
import projectSelect from '~/project_select';

document.addEventListener('DOMContentLoaded', () => {
  initFilePickers();
  initConfirmDangerModal();
  initSettingsPanels();
  dirtySubmitFactory(
    document.querySelectorAll('.js-general-settings-form, .js-general-permissions-form'),
  );
  mountBadgeSettings(GROUP_BADGE);
  setupTransferEdit('.js-group-transfer-form', '#new_parent_group_id');

  // Initialize Subgroups selector
  groupsSelect();

  projectSelect();

  return new TransferDropdown();
});
