/* global Mousetrap */
/* global ShortcutsNavigation */

class ShortcutsWiki extends ShortcutsNavigation {
  constructor() {
    super();
    Mousetrap.bind('e', this.editWiki);
  }

  editWiki() {
    this.gl.utils.visitUrl($('.wiki-edit').attr('href'));
  }
}

module.exports = ShortcutsWiki;
