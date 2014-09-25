#= require shortcuts_navigation

class @ShortcutsIssueable extends ShortcutsNavigation
  constructor: (isMergeRequest) ->
    super()
    Mousetrap.bind('a', ->
      $('.js-assignee').select2('open')
      return false
    )
    Mousetrap.bind('m', ->
      $('.js-milestone').select2('open')
      return false
    )
    
    if isMergeRequest
      @enabledHelp.push('.hidden-shortcut.merge_reuests')
    else
      @enabledHelp.push('.hidden-shortcut.issues')

