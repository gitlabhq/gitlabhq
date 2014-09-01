#= require shortcuts

class @ShortcutsDashboardNavigation extends Shortcuts
 constructor: ->
   super()
   Mousetrap.bind('g a', -> ShortcutsDashboardNavigation.findAndollowLink('.shortcuts-activity'))
   Mousetrap.bind('g p', -> ShortcutsDashboardNavigation.findAndollowLink('.shortcuts-projects'))
   Mousetrap.bind('g i', -> ShortcutsDashboardNavigation.findAndollowLink('.shortcuts-issues'))
   Mousetrap.bind('g m', -> ShortcutsDashboardNavigation.findAndollowLink('.shortcuts-merge_requests'))

 @findAndollowLink: (selector) ->
   link = $(selector).attr('href')
   if link
     window.location = link
