#= require mithril
#= require_directory ./components
#= require_directory .

$ ->
  # Render all the buttons
  $('.discussion').each ->
    $this = $(this)

    $('.js-line-comment', $(this)).each ->
      m.mount $(this).get(0), m(CommentButton,
        discussion_id: $this.data('discussion-id')
        note_id: $(this).data('id')
        resolved: !!$(this).data('resolved')
      )
