import ZenMode from '~/zen_mode';
import initNewRelease from '~/releases/mount_new';

document.addEventListener('DOMContentLoaded', () => {
  new ZenMode(); // eslint-disable-line no-new
  initNewRelease();
});
