import Mousetrap from 'mousetrap';
import ShortcutsNavigation from './shortcuts_navigation';

export default class ShortcutsFindFile extends ShortcutsNavigation {
  constructor(projectFindFile) {
    super();

    const oldStopCallback = Mousetrap.stopCallback;
    this.projectFindFile = projectFindFile;

    Mousetrap.stopCallback = (e, element, combo) => {
      if (
        element === this.projectFindFile.inputElement[0] &&
        (combo === 'up' || combo === 'down' || combo === 'esc' || combo === 'enter')
      ) {
        // when press up/down key in textbox, cusor prevent to move to home/end
        event.preventDefault();
        return false;
      }

      return oldStopCallback(e, element, combo);
    };

    Mousetrap.bind('up', this.projectFindFile.selectRowUp);
    Mousetrap.bind('down', this.projectFindFile.selectRowDown);
    Mousetrap.bind('esc', this.projectFindFile.goToTree);
    Mousetrap.bind('enter', this.projectFindFile.goToBlob);
  }
}
