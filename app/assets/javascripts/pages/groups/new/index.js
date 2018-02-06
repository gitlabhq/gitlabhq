import BindInOut from '~/behaviors/bind_in_out';
import Group from '~/group';
import groupAvatar from '~/group_avatar';

export default () => {
  BindInOut.initAll();
  new Group(); // eslint-disable-line no-new
  groupAvatar();
};
