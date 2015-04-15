#= require shortcuts

class @ShortcutsDashboardNavigation extends Shortcuts
 constructor: ->
   super()
   Mousetrap.bind('g a', -> ShortcutsDashboardNavigation.findAndFollowLink('.shortcuts-activity'))
   Mousetrap.bind('g i', -> ShortcutsDashboardNavigation.findAndFollowLink('.shortcuts-issues'))
   Mousetrap.bind('g m', -> ShortcutsDashboardNavigation.findAndFollowLink('.shortcuts-merge_requests'))
   Mousetrap.bind('g p', -> ShortcutsDashboardNavigation.findAndFollowLink('.shortcuts-projects'))

 @findAndFollowLink: (selector) ->
   link = $(selector).attr('href')
   if link
     window.location = link
