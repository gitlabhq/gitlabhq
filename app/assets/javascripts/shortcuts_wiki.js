import Mousetrap from 'mousetrap';
import ShortcutsNavigation from './shortcuts_navigation';
import findAndFollowLink from './shortcuts_dashboard_navigation';

export default class ShortcutsWiki extends ShortcutsNavigation {
  constructor() {
    super();
    Mousetrap.bind('e', ShortcutsWiki.editWiki);
  }

  static editWiki() {
    findAndFollowLink('.js-wiki-edit');
  }
}
