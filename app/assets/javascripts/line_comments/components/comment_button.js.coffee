@CommentButton =
  model: (args) ->
    @note = m.prop(args.noteId or undefined)
    @resolved = m.prop(args.resolved or false)
    return
  controller: (args) ->
    @model = new CommentButton.model(args)

    @resolvedText = m.prop =>
      if @model.resolved() then 'Mark as un-resolved' else 'Mark as resolved'

    @resolveLine = =>
      @model.resolved(!@model.resolved())
      LinesObserver.trigger(@model.resolved(), @model.note())

    return
  view: (ctrl) ->
    buttonText = ctrl.resolvedText()()
    isActive = if ctrl.model.resolved() then 'is-active' else ''

    # Return the view elements
    m('button',
      'aria-label': buttonText
      title: buttonText
      type: 'button'
      class: "line-resolve-btn #{isActive}"
      onclick: ctrl.resolveLine
      config: (el) ->
        $(el)
          .tooltip('hide')
          .tooltip()
          .tooltip('fixTitle')
    , [
      m('i',
        class: 'fa fa-check'
      )
      m('span',
        class: 'sr-only'
      , buttonText)
    ])
