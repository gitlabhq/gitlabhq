import Mousetrap from 'mousetrap';
import ShortcutsNavigation from './shortcuts_navigation';

export default class ShortcutsFindFile extends ShortcutsNavigation {
  constructor(projectFindFile) {
    super();

    const oldStopCallback = Mousetrap.prototype.stopCallback;

    Mousetrap.prototype.stopCallback = function customStopCallback(e, element, combo) {
      if (
        element === projectFindFile.inputElement[0] &&
        (combo === 'up' || combo === 'down' || combo === 'esc' || combo === 'enter')
      ) {
        // when press up/down key in textbox, cursor prevent to move to home/end
        e.preventDefault();
        return false;
      }

      return oldStopCallback.call(this, e, element, combo);
    };

    Mousetrap.bind('up', projectFindFile.selectRowUp);
    Mousetrap.bind('down', projectFindFile.selectRowDown);
    Mousetrap.bind('esc', projectFindFile.goToTree);
    Mousetrap.bind('enter', projectFindFile.goToBlob);
  }
}
