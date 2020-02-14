import ZenMode from '~/zen_mode';
import initEditRelease from '~/releases/mount_edit';

document.addEventListener('DOMContentLoaded', () => {
  new ZenMode(); // eslint-disable-line no-new
  initEditRelease();
});
