import Mousetrap from 'mousetrap';
import findAndFollowLink from '../../lib/utils/navigation_utility';
import ShortcutsNavigation from './shortcuts_navigation';

export default class ShortcutsWiki extends ShortcutsNavigation {
  constructor() {
    super();
    Mousetrap.bind('e', ShortcutsWiki.editWiki);
  }

  static editWiki() {
    findAndFollowLink('.js-wiki-edit');
  }
}
