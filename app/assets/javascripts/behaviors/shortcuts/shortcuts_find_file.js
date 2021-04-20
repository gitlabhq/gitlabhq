import Mousetrap from 'mousetrap';
import {
  keysFor,
  PROJECT_FILES_MOVE_SELECTION_UP,
  PROJECT_FILES_MOVE_SELECTION_DOWN,
  PROJECT_FILES_OPEN_SELECTION,
  PROJECT_FILES_GO_BACK,
} from '~/behaviors/shortcuts/keybindings';
import ShortcutsNavigation from './shortcuts_navigation';

export default class ShortcutsFindFile extends ShortcutsNavigation {
  constructor(projectFindFile) {
    super();

    const oldStopCallback = Mousetrap.prototype.stopCallback;

    Mousetrap.prototype.stopCallback = function customStopCallback(e, element, combo) {
      if (
        element === projectFindFile.inputElement[0] &&
        (keysFor(PROJECT_FILES_MOVE_SELECTION_UP).includes(combo) ||
          keysFor(PROJECT_FILES_MOVE_SELECTION_DOWN).includes(combo) ||
          keysFor(PROJECT_FILES_GO_BACK).includes(combo) ||
          keysFor(PROJECT_FILES_OPEN_SELECTION).includes(combo))
      ) {
        // when press up/down key in textbox, cursor prevent to move to home/end
        e.preventDefault();
        return false;
      }

      return oldStopCallback.call(this, e, element, combo);
    };

    Mousetrap.bind(keysFor(PROJECT_FILES_MOVE_SELECTION_UP), projectFindFile.selectRowUp);
    Mousetrap.bind(keysFor(PROJECT_FILES_MOVE_SELECTION_DOWN), projectFindFile.selectRowDown);
    Mousetrap.bind(keysFor(PROJECT_FILES_GO_BACK), projectFindFile.goToTree);
    Mousetrap.bind(keysFor(PROJECT_FILES_OPEN_SELECTION), projectFindFile.goToBlob);
  }
}
