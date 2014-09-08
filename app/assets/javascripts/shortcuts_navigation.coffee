#= require shortcuts

class @ShortcutsNavigation extends Shortcuts
  constructor: ->
    super()
    Mousetrap.bind('g a', -> ShortcutsNavigation.findAndollowLink('.shortcuts-activity'))
    Mousetrap.bind('g f', -> ShortcutsNavigation.findAndollowLink('.shortcuts-tree'))
    Mousetrap.bind('g c', -> ShortcutsNavigation.findAndollowLink('.shortcuts-commits'))
    Mousetrap.bind('g n', -> ShortcutsNavigation.findAndollowLink('.shortcuts-network'))
    Mousetrap.bind('g g', -> ShortcutsNavigation.findAndollowLink('.shortcuts-graphs'))
    Mousetrap.bind('g i', -> ShortcutsNavigation.findAndollowLink('.shortcuts-issues'))
    Mousetrap.bind('g m', -> ShortcutsNavigation.findAndollowLink('.shortcuts-merge_requests'))
    Mousetrap.bind('g w', -> ShortcutsNavigation.findAndollowLink('.shortcuts-wiki'))
    Mousetrap.bind('g s', -> ShortcutsNavigation.findAndollowLink('.shortcuts-snippets'))
    @enabledHelp.push('.hidden-shortcut.project')
   
  @findAndollowLink: (selector) ->
   link = $(selector).attr('href')
   if link
     window.location = link
