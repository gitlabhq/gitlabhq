import Mousetrap from 'mousetrap';
import ShortcutsNavigation from './shortcuts_navigation';

export default class ShortcutsNetwork extends ShortcutsNavigation {
  constructor(graph) {
    super();

    Mousetrap.bind(['left', 'h'], graph.scrollLeft);
    Mousetrap.bind(['right', 'l'], graph.scrollRight);
    Mousetrap.bind(['up', 'k'], graph.scrollUp);
    Mousetrap.bind(['down', 'j'], graph.scrollDown);
    Mousetrap.bind(['shift+up', 'shift+k'], graph.scrollTop);
    Mousetrap.bind(['shift+down', 'shift+j'], graph.scrollBottom);

    this.enabledHelp.push('.hidden-shortcut.network');
  }
}
