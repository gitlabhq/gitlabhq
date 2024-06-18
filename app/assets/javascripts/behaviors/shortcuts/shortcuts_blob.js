import { PROJECT_FILES_GO_TO_PERMALINK } from '~/behaviors/shortcuts/keybindings';
import { moveToFilePermalink } from '~/blob/utils';

export default class ShortcutsBlob {
  constructor(shortcuts) {
    shortcuts.add(PROJECT_FILES_GO_TO_PERMALINK, moveToFilePermalink);
  }
}
