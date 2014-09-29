class @Shortcuts
  constructor: ->
    @enabledHelp = []
    Mousetrap.reset()
    Mousetrap.bind('?', @selectiveHelp)
    Mousetrap.bind('s', Shortcuts.focusSearch)

  selectiveHelp: (e) =>
    Shortcuts.showHelp(e, @enabledHelp)
      
  @showHelp: (e, location) ->
    if $('#modal-shortcuts').length > 0
      $('#modal-shortcuts').modal('show')
    else
      $.ajax(
        url: '/help/shortcuts',
        dataType: 'script',
        success: (e) ->
          if location and location.length > 0
            for l in location
              $(l).show()
          else
            $('.hidden-shortcut').show()
            $('.js-more-help-button').remove()
      )
      e.preventDefault()

  @focusSearch: (e) ->
    $('#search').focus()
    e.preventDefault()
