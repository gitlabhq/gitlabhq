import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import BlobViewer from '~/blob/viewer/index';

document.addEventListener('DOMContentLoaded', () => {
  new ShortcutsNavigation(); // eslint-disable-line no-new
  new BlobViewer(); // eslint-disable-line no-new
});
