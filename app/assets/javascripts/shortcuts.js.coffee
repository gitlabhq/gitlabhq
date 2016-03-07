class @Shortcuts
  constructor: ->
    @enabledHelp = []
    Mousetrap.reset()
    Mousetrap.bind('?', @selectiveHelp)
    Mousetrap.bind('s', Shortcuts.focusSearch)
    Mousetrap.bind('t', -> Turbolinks.visit(findFileURL)) if findFileURL?

  selectiveHelp: (e) =>
    Shortcuts.showHelp(e, @enabledHelp)

  @showHelp: (e, location) ->
    if $('#modal-shortcuts').length > 0
      $('#modal-shortcuts').modal('show')
    else
      url = '/help/shortcuts'
      url = gon.relative_url_root + url if gon.relative_url_root?
      $.ajax(
        url: url,
        dataType: 'script',
        success: (e) ->
          if location and location.length > 0
            $(l).show() for l in location
          else
            $('.hidden-shortcut').show()
            $('.js-more-help-button').remove()
      )
      e.preventDefault()

  @focusSearch: (e) ->
    $('#search').focus()
    e.preventDefault()

$(document).on 'click.more_help', '.js-more-help-button', (e) ->
  $(@).remove()
  $('.hidden-shortcut').show()
  e.preventDefault()
