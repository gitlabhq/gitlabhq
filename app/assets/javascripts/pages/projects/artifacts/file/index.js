import BlobViewer from '~/blob/viewer/index';
import ShortcutsNavigation from '~/shortcuts_navigation';

export default function () {
  new ShortcutsNavigation(); // eslint-disable-line no-new
  new BlobViewer(); // eslint-disable-line no-new
}
