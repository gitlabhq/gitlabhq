import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import { BlobViewer } from '~/blob/viewer/index';

addShortcutsExtension(ShortcutsNavigation);
new BlobViewer(); // eslint-disable-line no-new
