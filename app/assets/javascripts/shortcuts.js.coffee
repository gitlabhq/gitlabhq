class @Shortcuts
  constructor: (skipResetBindings) ->
    @enabledHelp = []
    Mousetrap.reset() if not skipResetBindings
    Mousetrap.bind '?', @onToggleHelp
    Mousetrap.bind 's', Shortcuts.focusSearch
    Mousetrap.bind 'f', (e) => @focusFilter e
    Mousetrap.bind ['ctrl+shift+p', 'command+shift+p'], @toggleMarkdownPreview
    Mousetrap.bind('t', -> Turbolinks.visit(findFileURL)) if findFileURL?

  onToggleHelp: (e) =>
    e.preventDefault()
    Shortcuts.toggleHelp(@enabledHelp)

  toggleMarkdownPreview: (e) ->
    $(document).triggerHandler('markdown-preview:toggle', [e])

  @toggleHelp: (location) ->
    $modal = $('#modal-shortcuts')

    if $modal.length
      $modal.modal('toggle')
      return

  focusFilter: (e) ->
    @filterInput ?= $('input[type=search]', '.nav-controls')
    @filterInput.focus()
    e.preventDefault()

  @focusSearch: (e) ->
    $('#search').focus()
    e.preventDefault()


$(document).on 'click.more_help', '.js-more-help-button', (e) ->
  $(@).remove()
  $('.hidden-shortcut').show()
  e.preventDefault()

Mousetrap.stopCallback = (->
  defaultStopCallback = Mousetrap.stopCallback

  return (e, element, combo) ->
    # allowed shortcuts if textarea, input, contenteditable are focused
    if ['ctrl+shift+p', 'command+shift+p'].indexOf(combo) != -1
      return false
    else
      return defaultStopCallback.apply(@, arguments)
)()
