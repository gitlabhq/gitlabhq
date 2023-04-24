import findAndFollowLink from '~/lib/utils/navigation_utility';
import { EDIT_WIKI_PAGE } from './keybindings';
import ShortcutsNavigation from './shortcuts_navigation';

export default class ShortcutsWiki extends ShortcutsNavigation {
  constructor() {
    super();

    this.bindCommand(EDIT_WIKI_PAGE, ShortcutsWiki.editWiki);
  }

  static editWiki() {
    findAndFollowLink('.js-wiki-edit');
  }
}
