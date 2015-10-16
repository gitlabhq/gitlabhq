#= require shortcuts

class @ShortcutsNavigation extends Shortcuts
  constructor: ->
    super()
    Mousetrap.bind('g p', -> ShortcutsNavigation.findAndFollowLink('.shortcuts-project'))
    Mousetrap.bind('g e', -> ShortcutsNavigation.findAndFollowLink('.shortcuts-project-activity'))
    Mousetrap.bind('g f', -> ShortcutsNavigation.findAndFollowLink('.shortcuts-tree'))
    Mousetrap.bind('g c', -> ShortcutsNavigation.findAndFollowLink('.shortcuts-commits'))
    Mousetrap.bind('g b', -> ShortcutsNavigation.findAndFollowLink('.shortcuts-builds'))
    Mousetrap.bind('g n', -> ShortcutsNavigation.findAndFollowLink('.shortcuts-network'))
    Mousetrap.bind('g g', -> ShortcutsNavigation.findAndFollowLink('.shortcuts-graphs'))
    Mousetrap.bind('g i', -> ShortcutsNavigation.findAndFollowLink('.shortcuts-issues'))
    Mousetrap.bind('g m', -> ShortcutsNavigation.findAndFollowLink('.shortcuts-merge_requests'))
    Mousetrap.bind('g w', -> ShortcutsNavigation.findAndFollowLink('.shortcuts-wiki'))
    Mousetrap.bind('g s', -> ShortcutsNavigation.findAndFollowLink('.shortcuts-snippets'))
    @enabledHelp.push('.hidden-shortcut.project')

  @findAndFollowLink: (selector) ->
   link = $(selector).attr('href')
   if link
     window.location = link
