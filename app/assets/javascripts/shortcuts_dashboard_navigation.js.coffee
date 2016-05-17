#= require shortcuts

class @ShortcutsDashboardNavigation extends Shortcuts
 constructor: ->
   super()
   Mousetrap.bind('g a', -> ShortcutsDashboardNavigation.findAndFollowLink('.dashboard-shortcuts-activity'))
   Mousetrap.bind('g i', -> ShortcutsDashboardNavigation.findAndFollowLink('.dashboard-shortcuts-issues'))
   Mousetrap.bind('g m', -> ShortcutsDashboardNavigation.findAndFollowLink('.dashboard-shortcuts-merge_requests'))
   Mousetrap.bind('g p', -> ShortcutsDashboardNavigation.findAndFollowLink('.dashboard-shortcuts-projects'))

 @findAndFollowLink: (selector) ->
   link = $(selector).attr('href')
   if link
     window.location = link
