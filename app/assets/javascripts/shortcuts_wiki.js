/* eslint-disable class-methods-use-this*/
/* global Mousetrap */
/* global ShortcutsNavigation */

export default class ShortcutsWiki extends ShortcutsNavigation {
  constructor() {
    super();
    Mousetrap.bind('e', this.editWiki);
  }

  editWiki() {
    gl.utils.visitUrl($('.wiki-edit').attr('href'));
  }
}
