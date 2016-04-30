class @CreateIssueFromComment

  constructor: ->
    @hideOrShowCheckbox()

    $('#diffs').on 'click', '.create-issue-from-note', (e) =>
      $eventTarget = $(event.target)
      if $eventTarget.is('[type="checkbox"]:checked')
        $form = $eventTarget.closest('.js-discussion-note-form')
        @addFormatToTextArea $form
        @setUpListenerForFormSubmit $form
        @setUpListenerForNoteCreation()
      else if not $eventTarget.is('[type="checkbox"]:checked')
        @setBackToDefault($eventTarget)

  hideOrShowCheckbox: ->
    $('.merge-request').on 'createIssueFromComment:show', () ->
      $(this).find('.create-issue-from-note').removeClass('hidden')

  addFormatToTextArea: (form) ->
    textArea  = $(form).find('textarea.markdown-area')

    textNote = "Issue Title (Required)\n---\nDescription"
    $(textArea).val(textNote)

  setBackToDefault: (checkbox) ->
    $form = checkbox.closest('.js-discussion-note-form')
    textArea  = $form.find('textarea.markdown-area')

    $(textArea).val('')

  setUpListenerForFormSubmit: (form) ->
    $(form).on 'ajax:beforeSend', (e) =>
      e.preventDefault()
      textAreaValue = $(form).find('textarea.markdown-area').val()

      # ensure the user uses the format on the textarea
      if textAreaValue.indexOf('---') is -1
        @addFormatToTextArea(form)
        return false

      # check if the the title is present since it is required
      @textValueArr = textAreaValue.split('---')
      @projectId = $(form).closest('.tab-content').data('project-id')
      if $.trim(@textValueArr[0])
        @setUpListenerForNoteCreation()
      else
        return false

  setUpListenerForNoteCreation: ->
    $('#diffs')
      .off 'note:created'
      .on 'note:created', (e, note) =>
        @note = note
        @createIssue @textValueArr, @projectId

  createIssue: (textArr, projectId) ->
    # Create new Issue with API
    newIssue = Api.newIssue.bind(@)
    newIssue projectId, {
      title: textArr[0]
      description: textArr[1]
    }, (issue) =>
      if issue and issue.title
        $noteText = $('.js-task-list-container').find('note-text')
        projectUrl = $('.shortcuts-issues').attr('href')
        $noteText.append("<p><a href='#{projectUrl}/#{issue.iid}'></a></p>")
