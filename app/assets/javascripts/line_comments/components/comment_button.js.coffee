@CommentButton =
  model: (args) ->
    @note = m.prop(args.note_id or false)
    @resolved = m.prop(args.resolved or false)
    return
  controller: (args) ->
    @model = new CommentButton.model(args)

    @resolvedText = m.prop =>
      if @model.resolved() then 'Mark as un-resolved' else 'Mark as resolved'

    @resolveLine = =>
      @model.resolved(!@model.resolved())

    return
  view: (ctrl) ->
    buttonText = ctrl.resolvedText()()

    # Return the view elements
    m('button',
      'aria-label': buttonText
      class: 'line-resolve-btn'
      onclick: ctrl.resolveLine
    , [
      m('i',
        class: 'fa fa-check'
      )
      m('span',
        class: 'sr-only'
      , buttonText)
    ])
