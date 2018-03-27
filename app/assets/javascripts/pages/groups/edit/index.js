import groupAvatar from '~/group_avatar';
import TransferDropdown from '~/groups/transfer_dropdown';
import initConfirmDangerModal from '~/confirm_danger_modal';

document.addEventListener('DOMContentLoaded', () => {
  groupAvatar();
  new TransferDropdown(); // eslint-disable-line no-new
  initConfirmDangerModal();
});
