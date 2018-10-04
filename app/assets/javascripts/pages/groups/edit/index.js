import groupAvatar from '~/group_avatar';
import TransferDropdown from '~/groups/transfer_dropdown';
import initConfirmDangerModal from '~/confirm_danger_modal';
import initSettingsPanels from '~/settings_panels';
import mountBadgeSettings from '~/pages/shared/mount_badge_settings';
import { GROUP_BADGE } from '~/badges/constants';

document.addEventListener('DOMContentLoaded', () => {
  groupAvatar();
  new TransferDropdown(); // eslint-disable-line no-new
  initConfirmDangerModal();
  initSettingsPanels();
  mountBadgeSettings(GROUP_BADGE);
});
