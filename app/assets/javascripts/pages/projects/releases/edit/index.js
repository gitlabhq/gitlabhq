import ZenMode from '~/zen_mode';
import initEditRelease from '~/releases/detail';

document.addEventListener('DOMContentLoaded', () => {
  new ZenMode(); // eslint-disable-line no-new
  initEditRelease();
});
