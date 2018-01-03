/* eslint-disable class-methods-use-this */
/* global Mousetrap */

import ShortcutsNavigation from './shortcuts_navigation';
import findAndFollowLink from './shortcuts_dashboard_navigation';

export default class ShortcutsWiki extends ShortcutsNavigation {
  constructor() {
    super();
    Mousetrap.bind('e', this.editWiki);
  }

  editWiki() {
    findAndFollowLink('.js-wiki-edit');
  }
}
