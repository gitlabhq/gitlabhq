import findAndFollowLink from '~/lib/utils/navigation_utility';
import { EDIT_WIKI_PAGE } from './keybindings';
import ShortcutsNavigation from './shortcuts_navigation';

export default class ShortcutsWiki {
  constructor(shortcuts) {
    shortcuts.add(EDIT_WIKI_PAGE, ShortcutsWiki.editWiki);
  }

  static dependencies = [ShortcutsNavigation];

  static editWiki() {
    findAndFollowLink('.js-wiki-edit');
  }
}
