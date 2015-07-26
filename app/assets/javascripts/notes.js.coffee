#= require autosave
#= require dropzone
#= require dropzone_input
#= require gfm_auto_complete
#= require jquery.atwho
#= require task_list

class @Notes
  @interval: null

  constructor: (notes_url, note_ids, last_fetched_at, view) ->
    @notes_url = notes_url
    @note_ids = note_ids
    @last_fetched_at = last_fetched_at
    @view = view
    @noteable_url = document.URL
    @initRefresh()
    @setupMainTargetNoteForm()
    @cleanBinding()
    @addBinding()
    @initTaskList()

  addBinding: ->
    # add note to UI after creation
    $(document).on "ajax:success", ".js-main-target-form", @addNote
    $(document).on "ajax:success", ".js-discussion-note-form", @addDiscussionNote

    # change note in UI after update
    $(document).on "ajax:success", "form.edit_note", @updateNote

    # Edit note link
    $(document).on "click", ".js-note-edit", @showEditForm
    $(document).on "click", ".note-edit-cancel", @cancelEdit

    # Reopen and close actions for Issue/MR combined with note form submit
    $(document).on "click", ".js-note-target-reopen", @targetReopen
    $(document).on "click", ".js-note-target-close", @targetClose
    $(document).on "click", ".js-comment-button", @updateCloseButton
    $(document).on "keyup", ".js-note-text", @updateTargetButtons

    # remove a note (in general)
    $(document).on "click", ".js-note-delete", @removeNote

    # delete note attachment
    $(document).on "click", ".js-note-attachment-delete", @removeAttachment

    # reset main target form after submit
    $(document).on "ajax:complete", ".js-main-target-form", @reenableTargetFormSubmitButton
    $(document).on "ajax:success", ".js-main-target-form", @resetMainTargetForm

    # update the file name when an attachment is selected
    $(document).on "change", ".js-note-attachment-input", @updateFormAttachment

    # reply to diff/discussion notes
    $(document).on "click", ".js-discussion-reply-button", @replyToDiscussionNote

    # add diff note
    $(document).on "click", ".js-add-diff-note-button", @addDiffNote

    # hide diff note form
    $(document).on "click", ".js-close-discussion-note-form", @cancelDiscussionForm

    # fetch notes when tab becomes visible
    $(document).on "visibilitychange", @visibilityChange

    # Chrome doesn't fire keypress or keyup for Command+Enter, so we need keydown.
    $(document).on 'keydown', '.js-note-text', (e) ->
      return if e.originalEvent.repeat
      if e.keyCode == 10 || ((e.metaKey || e.ctrlKey) && e.keyCode == 13)
        $(@).closest('form').submit()

  cleanBinding: ->
    $(document).off "ajax:success", ".js-main-target-form"
    $(document).off "ajax:success", ".js-discussion-note-form"
    $(document).off "ajax:success", "form.edit_note"
    $(document).off "click", ".js-note-edit"
    $(document).off "click", ".note-edit-cancel"
    $(document).off "click", ".js-note-delete"
    $(document).off "click", ".js-note-attachment-delete"
    $(document).off "ajax:complete", ".js-main-target-form"
    $(document).off "ajax:success", ".js-main-target-form"
    $(document).off "click", ".js-discussion-reply-button"
    $(document).off "click", ".js-add-diff-note-button"
    $(document).off "visibilitychange"
    $(document).off "keydown", ".js-note-text"
    $(document).off "keyup", ".js-note-text"
    $(document).off "click", ".js-note-target-reopen"
    $(document).off "click", ".js-note-target-close"

    $('.note .js-task-list-container').taskList('disable')
    $(document).off 'tasklist:changed', '.note .js-task-list-container'

  initRefresh: ->
    clearInterval(Notes.interval)
    Notes.interval = setInterval =>
      @refresh()
    , 15000

  refresh: ->
    unless document.hidden or (@noteable_url != document.URL)
      @getContent()

  getContent: ->
    $.ajax
      url: @notes_url
      data: "last_fetched_at=" + @last_fetched_at
      dataType: "json"
      success: (data) =>
        notes = data.notes
        @last_fetched_at = data.last_fetched_at
        $.each notes, (i, note) =>
          @renderNote(note)


  ###
  Render note in main comments area.

  Note: for rendering inline notes use renderDiscussionNote
  ###
  renderNote: (note) ->
    # render note if it not present in loaded list
    # or skip if rendered
    if @isNewNote(note)
      @note_ids.push(note.id)
      $('ul.main-notes-list').append(note.html)
      @initTaskList()

  ###
  Check if note does not exists on page
  ###
  isNewNote: (note) ->
    $.inArray(note.id, @note_ids) == -1

  isParallelView: ->
    @view == 'parallel'

  ###
  Render note in discussion area.

  Note: for rendering inline notes use renderDiscussionNote
  ###
  renderDiscussionNote: (note) ->
    @note_ids.push(note.id)
    form = $("form[rel='" + note.discussion_id + "']")
    row = form.closest("tr")

    # is this the first note of discussion?
    if row.is(".js-temp-notes-holder")
      # insert the note and the reply button after the temp row
      row.after note.discussion_html

      # remove the note (will be added again below)
      row.next().find(".note").remove()

      # Add note to 'Changes' page discussions
      $(".notes[rel='" + note.discussion_id + "']").append note.html

      # Init discussion on 'Discussion' page if it is merge request page
      if $('body').attr('data-page').indexOf('projects:merge_request') == 0
        $('ul.main-notes-list').append(note.discussion_with_diff_html)
    else
      # append new note to all matching discussions
      $(".notes[rel='" + note.discussion_id + "']").append note.html

    # cleanup after successfully creating a diff/discussion note
    @removeDiscussionNoteForm(form)

  ###
  Called in response the main target form has been successfully submitted.

  Removes any errors.
  Resets text and preview.
  Resets buttons.
  ###
  resetMainTargetForm: ->
    form = $(".js-main-target-form")

    # remove validation errors
    form.find(".js-errors").remove()

    # reset text and preview
    form.find(".js-md-write-button").click()
    form.find(".js-note-text").val("").trigger "input"

    form.find(".js-note-text").data("autosave").reset()

  reenableTargetFormSubmitButton: ->
    form = $(".js-main-target-form")

    form.find(".js-note-text").trigger "input"

  ###
  Shows the main form and does some setup on it.

  Sets some hidden fields in the form.
  ###
  setupMainTargetNoteForm: ->

    # find the form
    form = $(".js-new-note-form")

    # insert the form after the button
    form.clone().replaceAll $(".js-main-target-form")
    form = form.prev("form")

    # show the form
    @setupNoteForm(form)

    # fix classes
    form.removeClass "js-new-note-form"
    form.addClass "js-main-target-form"

    # remove unnecessary fields and buttons
    form.find("#note_line_code").remove()
    form.find(".js-close-discussion-note-form").remove()

  ###
  General note form setup.

  deactivates the submit button when text is empty
  hides the preview button when text is empty
  setup GFM auto complete
  show the form
  ###
  setupNoteForm: (form) ->
    disableButtonIfEmptyField form.find(".js-note-text"), form.find(".js-comment-button")
    form.removeClass "js-new-note-form"
    form.find('.div-dropzone').remove()

    # setup preview buttons
    form.find(".js-md-write-button, .js-md-preview-button").tooltip placement: "left"
    previewButton = form.find(".js-md-preview-button")

    textarea = form.find(".js-note-text")

    textarea.on "input", ->
      if $(this).val().trim() isnt ""
        previewButton.removeClass("turn-off").addClass "turn-on"
      else
        previewButton.removeClass("turn-on").addClass "turn-off"

    new Autosave textarea, [
      "Note"
      form.find("#note_commit_id").val()
      form.find("#note_line_code").val()
      form.find("#note_noteable_type").val()
      form.find("#note_noteable_id").val()
    ]

    # remove notify commit author checkbox for non-commit notes
    form.find(".js-notify-commit-author").remove()  if form.find("#note_noteable_type").val() isnt "Commit"
    GitLab.GfmAutoComplete.setup()
    new DropzoneInput(form)
    form.show()

  ###
  Called in response to the new note form being submitted

  Adds new note to list.
  ###
  addNote: (xhr, note, status) =>
    @renderNote(note)
    @updateVotes()

  ###
  Called in response to the new note form being submitted

  Adds new note to list.
  ###
  addDiscussionNote: (xhr, note, status) =>
    @renderDiscussionNote(note)

  ###
  Called in response to the edit note form being submitted

  Updates the current note field.
  ###
  updateNote: (xhr, note, status) =>
    note_li = $(".note-row-" + note.id)
    note_li.replaceWith(note.html)
    note_li.find('.note-edit-form').hide()
    note_li.find('.note-body > .note-text').show()
    note_li.find('js-task-list-container').taskList('enable')
    @enableTaskList()

  ###
  Called in response to clicking the edit note link

  Replaces the note text with the note edit form
  Adds a hidden div with the original content of the note to fill the edit note form with
  if the user cancels
  ###
  showEditForm: (e) ->
    e.preventDefault()
    note = $(this).closest(".note")
    note.find(".note-body > .note-text").hide()
    note.find(".note-header").hide()
    base_form = note.find(".note-edit-form")
    form = base_form.clone().insertAfter(base_form)
    form.addClass('current-note-edit-form gfm-form')
    form.find('.div-dropzone').remove()

    # Show the attachment delete link
    note.find(".js-note-attachment-delete").show()

    # Setup markdown form
    GitLab.GfmAutoComplete.setup()
    new DropzoneInput(form)

    form.show()
    textarea = form.find("textarea")
    textarea.focus()

    # HACK (rspeicher/DouweM): Work around a Chrome 43 bug(?).
    # The textarea has the correct value, Chrome just won't show it unless we
    # modify it, so let's clear it and re-set it!
    value = textarea.val()
    textarea.val ""
    textarea.val value

    disableButtonIfEmptyField textarea, form.find(".js-comment-button")

  ###
  Called in response to clicking the edit note link

  Hides edit form
  ###
  cancelEdit: (e) ->
    e.preventDefault()
    note = $(this).closest(".note")
    note.find(".note-body > .note-text").show()
    note.find(".note-header").show()
    note.find(".current-note-edit-form").remove()

  ###
  Called in response to deleting a note of any kind.

  Removes the actual note from view.
  Removes the whole discussion if the last note is being removed.
  ###
  removeNote: ->
    note = $(this).closest(".note")
    notes = note.closest(".notes")

    # check if this is the last note for this line
    if notes.find(".note").length is 1

      # for discussions
      notes.closest(".discussion").remove()

      # for diff lines
      notes.closest("tr").remove()

    note.remove()

  ###
  Called in response to clicking the delete attachment link

  Removes the attachment wrapper view, including image tag if it exists
  Resets the note editing form
  ###
  removeAttachment: ->
    note = $(this).closest(".note")
    note.find(".note-attachment").remove()
    note.find(".note-body > .note-text").show()
    note.find(".js-note-attachment-delete").hide()
    note.find(".note-edit-form").hide()

  ###
  Called when clicking on the "reply" button for a diff line.

  Shows the note form below the notes.
  ###
  replyToDiscussionNote: (e) =>
    form = $(".js-new-note-form")
    replyLink = $(e.target).closest(".js-discussion-reply-button")
    replyLink.hide()

    # insert the form after the button
    form.clone().insertAfter replyLink

    # show the form
    @setupDiscussionNoteForm(replyLink, replyLink.next("form"))

  ###
  Shows the diff or discussion form and does some setup on it.

  Sets some hidden fields in the form.

  Note: dataHolder must have the "discussionId", "lineCode", "noteableType"
  and "noteableId" data attributes set.
  ###
  setupDiscussionNoteForm: (dataHolder, form) =>
    # setup note target
    form.attr "rel", dataHolder.data("discussionId")
    form.find("#line_type").val dataHolder.data("lineType")
    form.find("#note_commit_id").val dataHolder.data("commitId")
    form.find("#note_line_code").val dataHolder.data("lineCode")
    form.find("#note_noteable_type").val dataHolder.data("noteableType")
    form.find("#note_noteable_id").val dataHolder.data("noteableId")
    @setupNoteForm form
    form.find(".js-note-text").focus()
    form.addClass "js-discussion-note-form"

  ###
  Called when clicking on the "add a comment" button on the side of a diff line.

  Inserts a temporary row for the form below the line.
  Sets up the form and shows it.
  ###
  addDiffNote: (e) =>
    e.preventDefault()
    link = e.currentTarget
    form = $(".js-new-note-form")
    row = $(link).closest("tr")
    nextRow = row.next()
    hasNotes = nextRow.is(".notes_holder")
    addForm = false
    targetContent = ".notes_content"
    rowCssToAdd = "<tr class=\"notes_holder js-temp-notes-holder\"><td class=\"notes_line\" colspan=\"2\"></td><td class=\"notes_content\"></td></tr>"

    # In parallel view, look inside the correct left/right pane
    if @isParallelView()
      lineType = $(link).data("lineType")
      targetContent += "." + lineType
      rowCssToAdd = "<tr class=\"notes_holder js-temp-notes-holder\"><td class=\"notes_line\"></td><td class=\"notes_content parallel old\"></td><td class=\"notes_line\"></td><td class=\"notes_content parallel new\"></td></tr>"

    if hasNotes
      notesContent = nextRow.find(targetContent)
      if notesContent.length
        replyButton = notesContent.find(".js-discussion-reply-button:visible")
        if replyButton.length
          e.target = replyButton[0]
          $.proxy(@replyToDiscussionNote, replyButton[0], e).call()
        else
          # In parallel view, the form may not be present in one of the panes
          noteForm = notesContent.find(".js-discussion-note-form")
          if noteForm.length == 0
            addForm = true
    else
      # add a notes row and insert the form
      row.after rowCssToAdd
      addForm = true

    if addForm
      newForm = form.clone()
      newForm.appendTo row.next().find(targetContent)

      # show the form
      @setupDiscussionNoteForm $(link), newForm

  ###
  Called in response to "cancel" on a diff note form.

  Shows the reply button again.
  Removes the form and if necessary it's temporary row.
  ###
  removeDiscussionNoteForm: (form)->
    row = form.closest("tr")

    form.find(".js-note-text").data("autosave").reset()

    # show the reply button (will only work for replies)
    form.prev(".js-discussion-reply-button").show()
    if row.is(".js-temp-notes-holder")
      # remove temporary row for diff lines
      row.remove()
    else
      # only remove the form
      form.remove()


  cancelDiscussionForm: (e) =>
    e.preventDefault()
    form = $(".js-new-note-form")
    form = $(e.target).closest(".js-discussion-note-form")
    @removeDiscussionNoteForm(form)

  updateVotes: ->
    true

  ###
  Called after an attachment file has been selected.

  Updates the file name for the selected attachment.
  ###
  updateFormAttachment: ->
    form = $(this).closest("form")

    # get only the basename
    filename = $(this).val().replace(/^.*[\\\/]/, "")
    form.find(".js-attachment-filename").text filename

  ###
  Called when the tab visibility changes
  ###
  visibilityChange: =>
    @refresh()

  targetReopen: (e) =>
    @submitNoteForm($(e.target).parents('form'))

  targetClose: (e) =>
    @submitNoteForm($(e.target).parents('form'))

  submitNoteForm: (form) =>
    noteText = form.find(".js-note-text").val()
    if noteText.trim().length > 0
      form.submit()

  updateCloseButton: (e) =>
    textarea = $(e.target)
    form = textarea.parents('form')
    form.find('.js-note-target-close').text('Close')

  updateTargetButtons: (e) =>
    textarea = $(e.target)
    form = textarea.parents('form')

    if textarea.val().trim().length > 0
      form.find('.js-note-target-reopen').text('Comment & reopen')
      form.find('.js-note-target-close').text('Comment & close')
    else
      form.find('.js-note-target-reopen').text('Reopen')
      form.find('.js-note-target-close').text('Close')

  initTaskList: ->
    @enableTaskList()
    $(document).on 'tasklist:changed', '.note .js-task-list-container', @updateTaskList

  enableTaskList: ->
    $('.note .js-task-list-container').taskList('enable')

  updateTaskList: ->
    $('form', this).submit()
