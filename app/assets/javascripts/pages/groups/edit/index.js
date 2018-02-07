import groupAvatar from '~/group_avatar';
import TransferDropdown from '~/groups/transfer_dropdown';

export default () => {
  groupAvatar();
  new TransferDropdown(); // eslint-disable-line no-new
};
