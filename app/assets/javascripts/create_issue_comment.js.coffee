class @CreateIssueFromComment

  constructor: ->
    @hideOrShowCheckbox()

    $('.diffs').on 'click', '.create-issue-from-note', (e) =>
      $eventTarget = $(event.target)
      if $eventTarget.is('[type="checkbox"]:checked')
        $form = $eventTarget.closest('.js-discussion-note-form')
        @addFormatToTextArea $form
        @setUpListenerForFormSubmit $form
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
      textValueArr = textAreaValue.split('---')
      if $.trim(textValueArr[0])
        @createIssue textValueArr, $(form).closest('.tab-content').data('project-id')
      else
        return false

  createIssue: (textArr, projectId) ->
    # Create new label with API
    Api.newIssue projectId, {
      title: textArr[0]
      description: textArr[1] if textArr[1]
    }, (issue) ->
      if issue
        console.log 'crap'
