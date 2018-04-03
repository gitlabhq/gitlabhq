import ZenMode from '~/zen_mode';
import initEpicShow from 'ee/epics/epic_show/epic_show_bundle';
import '~/notes/index';

document.addEventListener('DOMContentLoaded', () => {
  new ZenMode(); // eslint-disable-line no-new
  initEpicShow();
});
