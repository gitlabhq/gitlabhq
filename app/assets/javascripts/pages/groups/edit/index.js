import initAvatarPicker from '~/avatar_picker';
import TransferDropdown from '~/groups/transfer_dropdown';
import initConfirmDangerModal from '~/confirm_danger_modal';
import initSettingsPanels from '~/settings_panels';
import dirtySubmitFactory from '~/dirty_submit/dirty_submit_factory';
import mountBadgeSettings from '~/pages/shared/mount_badge_settings';
import { GROUP_BADGE } from '~/badges/constants';
import groupsSelect from '~/groups_select';
import projectSelect from '~/project_select';

document.addEventListener('DOMContentLoaded', () => {
  initAvatarPicker();
  new TransferDropdown(); // eslint-disable-line no-new
  initConfirmDangerModal();
  initSettingsPanels();
  dirtySubmitFactory(
    document.querySelectorAll('.js-general-settings-form, .js-general-permissions-form'),
  );
  mountBadgeSettings(GROUP_BADGE);

  // Initialize Subgroups selector
  groupsSelect();

  projectSelect();
});
