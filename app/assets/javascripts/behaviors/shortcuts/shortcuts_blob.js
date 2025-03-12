import { PROJECT_FILES_GO_TO_PERMALINK } from '~/behaviors/shortcuts/keybindings';
import { moveToFilePermalink } from '~/blob/utils';

export default class ShortcutsBlob {
  constructor(shortcuts) {
    const { blobOverflowMenu } = gon.features ?? {};
    if (blobOverflowMenu) {
      // TODO: Remove ShortcutsBlob entirely once these feature flags are removed.
      return;
    }

    shortcuts.add(PROJECT_FILES_GO_TO_PERMALINK, moveToFilePermalink);
  }
}
