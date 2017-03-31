/* global Mousetrap */
/* global ShortcutsNavigation */

export default class ShortcutsWiki extends ShortcutsNavigation {
  constructor() {
    super();
    this.$wikiEdit = $('.wiki-edit');
    Mousetrap.bind('e', this.editWiki.bind(this));
  }

  editWiki() {
    gl.utils.visitUrl(this.$wikiEdit.attr('href'));
  }
}
