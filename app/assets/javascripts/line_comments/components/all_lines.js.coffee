@AllLines =
  controller: (args) ->
    @noteIds = m.prop(args.noteIds || [])
    @resolvedCount = m.prop(args.resolvedNoteIds || [])
    @resolvedtext = m.prop =>
      "#{@resolvedCount().length}/#{@noteIds().length} comments resolved"
    @resolveButtontext = m.prop =>
      'Resolve all line comments'

    LinesObserver.register (resolved, noteId) =>
      if resolved
        @resolvedCount().push noteId
      else
        @resolvedCount().splice @resolvedCount().indexOf(noteId), 1
    return
  view: (ctrl) ->
    m('div',
      class: 'line-resolve-all'
    ,[
      m('button',
        'aria-label': ctrl.resolveButtontext()()
        class: 'btn btn-gray'
        type: 'button'
      , ctrl.resolveButtontext()())
      m('span',
        class: 'line-resolve-text'
      , ctrl.resolvedtext()())
    ])
