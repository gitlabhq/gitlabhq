#= require mithril
#= require_directory ./observers
#= require_directory ./components
#= require_directory .

$ ->
  allNoteIds = []
  resolvedNoteIds = []
  # Render all the buttons
  $('.discussion').each ->
    $this = $(this)

    $('.js-line-comment', $(this)).each ->
      resolved = !!$(this).data('resolved')
      allNoteIds.push $(this).data('id')
      resolvedNoteIds.push $(this).data('id') if resolved

      m.mount $(this).get(0), m(CommentButton,
        discussionId: $this.data('discussion-id')
        noteId: $(this).data('id')
        resolved: !!$(this).data('resolved')
      )

  m.mount $('.js-line-comments-all').get(0), m(AllLines,
    noteIds: allNoteIds
    resolvedNoteIds: resolvedNoteIds
  )
