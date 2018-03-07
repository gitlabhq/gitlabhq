import groupAvatar from '~/group_avatar';
import TransferDropdown from '~/groups/transfer_dropdown';

document.addEventListener('DOMContentLoaded', () => {
  groupAvatar();
  new TransferDropdown(); // eslint-disable-line no-new
});
