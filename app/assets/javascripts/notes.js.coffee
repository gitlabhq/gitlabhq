class Notes
  @interval: null

  constructor: (notes_url, note_ids, last_fetched_at) ->
    @notes_url = notes_url
    @notes_url = gon.relative_url_root + @notes_url if gon.relative_url_root?
    @note_ids = note_ids
    @last_fetched_at = last_fetched_at
    @initRefresh()
    @setupMainTargetNoteForm()
    @cleanBinding()
    @addBinding()

  addBinding: ->
    # add note to UI after creation
    $(document).on "ajax:success", ".js-main-target-form", @addNote
    $(document).on "ajax:success", ".js-discussion-note-form", @addDiscussionNote

        # change note in UI after update
    $(document).on "ajax:success", "form.edit_note", @updateNote

    # Edit note link
    $(document).on "click", ".js-note-edit", @showEditForm
    $(document).on "click", ".note-edit-cancel", @cancelEdit

    # remove a note (in general)
    $(document).on "click", ".js-note-delete", @removeNote

    # delete note attachment
    $(document).on "click", ".js-note-attachment-delete", @removeAttachment

    # Preview button
    $(document).on "click", ".js-note-preview-button", @previewNote

    # Preview button
    $(document).on "click", ".js-note-write-button", @writeNote

    # reset main target form after submit
    $(document).on "ajax:complete", ".js-main-target-form", @resetMainTargetForm

    # attachment button
    $(document).on "click", ".js-choose-note-attachment-button", @chooseNoteAttachment

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

    @notes_forms = '.js-main-target-form textarea, .js-discussion-note-form textarea'
    $(document).on('keypress', @notes_forms, (e)->
      if e.keyCode == 10 || (e.ctrlKey && e.keyCode == 13)
        $(@).parents('form').submit()
    )

  cleanBinding: ->
    $(document).off "ajax:success", ".js-main-target-form"
    $(document).off "ajax:success", ".js-discussion-note-form"
    $(document).off "ajax:success", "form.edit_note"
    $(document).off "click", ".js-note-edit"
    $(document).off "click", ".note-edit-cancel"
    $(document).off "click", ".js-note-delete"
    $(document).off "click", ".js-note-attachment-delete"
    $(document).off "click", ".js-note-preview-button"
    $(document).off "click", ".js-note-write-button"
    $(document).off "ajax:complete", ".js-main-target-form"
    $(document).off "click", ".js-choose-note-attachment-button"
    $(document).off "click", ".js-discussion-reply-button"
    $(document).off "click", ".js-add-diff-note-button"
    $(document).off "visibilitychange"
    $(document).off "keypress", @notes_forms


  initRefresh: ->
    clearInterval(Notes.interval)
    Notes.interval = setInterval =>
      @refresh()
    , 15000

  refresh: ->
    @getContent() unless document.hidden

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
      code = "#note_" + note.id + " .highlight pre code"
      $(code).each (i, e) ->
        hljs.highlightBlock(e)


  ###
  Check if note does not exists on page
  ###
  isNewNote: (note) ->
    $.inArray(note.id, @note_ids) == -1


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
  Shows write note textarea.
  ###
  writeNote: (e) ->
    e.preventDefault()
    form = $(this).closest("form")
    # toggle tabs
    form.find(".js-note-write-button").parent().addClass "active"
    form.find(".js-note-preview-button").parent().removeClass "active"

    # toggle content
    form.find(".note-write-holder").show()
    form.find(".note-preview-holder").hide()

  ###
  Shows the note preview.

  Lets the server render GFM into Html and displays it.
  ###
  previewNote: (e) ->
    e.preventDefault()
    form = $(this).closest("form")
    # toggle tabs
    form.find(".js-note-write-button").parent().removeClass "active"
    form.find(".js-note-preview-button").parent().addClass "active"

    # toggle content
    form.find(".note-write-holder").hide()
    form.find(".note-preview-holder").show()

    preview = form.find(".js-note-preview")
    noteText = form.find(".js-note-text").val()
    if noteText.trim().length is 0
      preview.text "Nothing to preview."
    else
      preview.text "Loading..."
      $.post($(this).data("url"),
        note: noteText
      ).success (previewData) ->
        preview.html previewData

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
    form.find(".js-note-write-button").click()
    form.find(".js-note-text").val("").trigger "input"

  ###
  Called when clicking the "Choose File" button.

  Opens the file selection dialog.
  ###
  chooseNoteAttachment: ->
    form = $(this).closest("form")
    form.find(".js-note-attachment-input").click()

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

    # setup preview buttons
    form.find(".js-note-write-button, .js-note-preview-button").tooltip placement: "left"
    previewButton = form.find(".js-note-preview-button")
    form.find(".js-note-text").on "input", ->
      if $(this).val().trim() isnt ""
        previewButton.removeClass("turn-off").addClass "turn-on"
      else
        previewButton.removeClass("turn-on").addClass "turn-off"


    # remove notify commit author checkbox for non-commit notes
    form.find(".js-notify-commit-author").remove()  if form.find("#note_noteable_type").val() isnt "Commit"
    GitLab.GfmAutoComplete.setup()
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
    note_li = $("#note_" + note.id)
    note_li.replaceWith(note.html)
    code = "#note_" + note.id + " .highlight pre code"
    $(code).each (i, e) ->
      hljs.highlightBlock(e)

  ###
  Called in response to clicking the edit note link

  Replaces the note text with the note edit form
  Adds a hidden div with the original content of the note to fill the edit note form with
  if the user cancels
  ###
  showEditForm: (e) ->
    e.preventDefault()
    note = $(this).closest(".note")
    note.find(".note-text").hide()

    # Show the attachment delete link
    note.find(".js-note-attachment-delete").show()
    GitLab.GfmAutoComplete.setup()
    form = note.find(".note-edit-form")
    form.show()
    form.find("textarea").focus()

  ###
  Called in response to clicking the edit note link

  Hides edit form
  ###
  cancelEdit: (e) ->
    e.preventDefault()
    note = $(this).closest(".note")
    note.find(".note-text").show()
    note.find(".js-note-attachment-delete").hide()
    note.find(".note-edit-form").hide()

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
    note.find(".note-text").show()
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
    form.find("#note_commit_id").val dataHolder.data("commitId")
    form.find("#note_line_code").val dataHolder.data("lineCode")
    form.find("#note_noteable_type").val dataHolder.data("noteableType")
    form.find("#note_noteable_id").val dataHolder.data("noteableId")
    @setupNoteForm form
    form.find(".js-note-text").focus()
    form.addClass "js-discussion-note-form"

  ###
  General note form setup.

  deactivates the submit button when text is empty
  hides the preview button when text is empty
  setup GFM auto complete
  show the form
  ###
  setupNoteForm: (form) =>
    disableButtonIfEmptyField form.find(".js-note-text"), form.find(".js-comment-button")
    form.removeClass "js-new-note-form"
    form.removeClass "js-new-note-form"
    GitLab.GfmAutoComplete.setup()

    # setup preview buttons
    previewButton = form.find(".js-note-preview-button")
    form.find(".js-note-text").on "input", ->
      if $(this).val().trim() isnt ""
        previewButton.removeClass("turn-off").addClass "turn-on"
      else
        previewButton.removeClass("turn-on").addClass "turn-off"

    form.show()

  ###
  Called when clicking on the "add a comment" button on the side of a diff line.

  Inserts a temporary row for the form below the line.
  Sets up the form and shows it.
  ###
  addDiffNote: (e) =>
    e.preventDefault()
    link = e.target
    form = $(".js-new-note-form")
    row = $(link).closest("tr")
    nextRow = row.next()

    # does it already have notes?
    if nextRow.is(".notes_holder")
      replyButton = nextRow.find(".js-discussion-reply-button")
      if replyButton.length > 0
        $.proxy(@replyToDiscussionNote, replyButton).call()
    else
      # add a notes row and insert the form
      row.after "<tr class=\"notes_holder js-temp-notes-holder\"><td class=\"notes_line\" colspan=\"2\"></td><td class=\"notes_content\"></td></tr>"
      form.clone().appendTo row.next().find(".notes_content")

      # show the form
      @setupDiscussionNoteForm $(link), row.next().find("form")

  ###
  Called in response to "cancel" on a diff note form.

  Shows the reply button again.
  Removes the form and if necessary it's temporary row.
  ###
  removeDiscussionNoteForm: (form)->
    row = form.closest("tr")

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
    (new NotesVotes).updateVotes()

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

@Notes = Notes
