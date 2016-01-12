class @ShortcutsTree extends ShortcutsNavigation
  constructor: ->
    super()
    Mousetrap.bind('t', -> ShortcutsTree.findAndFollowLink('.shortcuts-find-file'))
