#= require autosave
#= require autosize
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
    @notesCountBadge ||= $(".issuable-details").find(".notes-tab .badge")
    @basePollingInterval = 15000
    @maxPollingSteps = 4

    @cleanBinding()
    @addBinding()
    @setPollingInterval()
    @setupMainTargetNoteForm()
    @initTaskList()

  addBinding: ->
    # add note to UI after creation
    $(document).on "ajax:success", ".js-main-target-form", @addNote
    $(document).on "ajax:success", ".js-discussion-note-form", @addDiscussionNote

    # catch note ajax errors
    $(document).on "ajax:error", ".js-main-target-form", @addNoteError

    # change note in UI after update
    $(document).on "ajax:success", "form.edit-note", @updateNote

    # Edit note link
    $(document).on "click", ".js-note-edit", @showEditForm
    $(document).on "click", ".note-edit-cancel", @cancelEdit

    # Reopen and close actions for Issue/MR combined with note form submit
    $(document).on "click", ".js-comment-button", @updateCloseButton
    $(document).on "keyup input", ".js-note-text", @updateTargetButtons

    # remove a note (in general)
    $(document).on "click", ".js-note-delete", @removeNote

    # delete note attachment
    $(document).on "click", ".js-note-attachment-delete", @removeAttachment

    # reset main target form after submit
    $(document).on "ajax:complete", ".js-main-target-form", @reenableTargetFormSubmitButton
    $(document).on "ajax:success", ".js-main-target-form", @resetMainTargetForm

    # reset main target form when clicking discard
    $(document).on "click", ".js-note-discard", @resetMainTargetForm

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

    # when issue status changes, we need to refresh data
    $(document).on "issuable:change", @refresh

    # when a key is clicked on the notes
    $(document).on "keydown", ".js-note-text", @keydownNoteText

  cleanBinding: ->
    $(document).off "ajax:success", ".js-main-target-form"
    $(document).off "ajax:success", ".js-discussion-note-form"
    $(document).off "ajax:success", "form.edit-note"
    $(document).off "click", ".js-note-edit"
    $(document).off "click", ".note-edit-cancel"
    $(document).off "click", ".js-note-delete"
    $(document).off "click", ".js-note-attachment-delete"
    $(document).off "ajax:complete", ".js-main-target-form"
    $(document).off "ajax:success", ".js-main-target-form"
    $(document).off "click", ".js-discussion-reply-button"
    $(document).off "click", ".js-add-diff-note-button"
    $(document).off "visibilitychange"
    $(document).off "keyup", ".js-note-text"
    $(document).off "click", ".js-note-target-reopen"
    $(document).off "click", ".js-note-target-close"
    $(document).off "click", ".js-note-discard"
    $(document).off "keydown", ".js-note-text"

    $('.note .js-task-list-container').taskList('disable')
    $(document).off 'tasklist:changed', '.note .js-task-list-container'

  keydownNoteText: (e) =>
    return if isMetaKey e

    $textarea = $(e.target)

    # Edit previous note when UP arrow is hit
    switch e.which
      when 38
        return unless $textarea.val() is ''

        myLastNote = $("li.note[data-author-id='#{gon.current_user_id}'][data-editable]:last")
        if myLastNote.length
          myLastNoteEditBtn = myLastNote.find('.js-note-edit')
          myLastNoteEditBtn.trigger('click', [true, myLastNote])

      # Cancel creating diff note or editing any note when ESCAPE is hit
      when 27
        discussionNoteForm = $textarea.closest('.js-discussion-note-form')
        if discussionNoteForm.length
          if $textarea.val() isnt ''
            return unless confirm('Are you sure you want to cancel creating this comment?')

          @removeDiscussionNoteForm(discussionNoteForm)
          return

        editNote = $textarea.closest('.note')
        if editNote.length
          originalText = $textarea.closest('form').data('original-note')
          newText = $textarea.val()
          if originalText isnt newText
            return unless confirm('Are you sure you want to cancel editing this comment?')

          @removeNoteEditForm(editNote)


  isMetaKey = (e) ->
    (e.metaKey or e.ctrlKey or e.altKey or e.shiftKey)

  initRefresh: ->
    clearInterval(Notes.interval)
    Notes.interval = setInterval =>
      @refresh()
    , @pollingInterval

  refresh: =>
    if not document.hidden and document.URL.indexOf(@noteable_url) is 0
      @getContent()

  getContent: ->
    return if @refreshing

    @refreshing = true

    $.ajax
      url: @notes_url
      data: "last_fetched_at=" + @last_fetched_at
      dataType: "json"
      success: (data) =>
        notes = data.notes
        @last_fetched_at = data.last_fetched_at
        @setPollingInterval(data.notes.length)
        $.each notes, (i, note) =>
          if note.discussion_with_diff_html?
            @renderDiscussionNote(note)
          else
            @renderNote(note)
    .always () =>
      @refreshing = false

  ###
  Increase @pollingInterval up to 120 seconds on every function call,
  if `shouldReset` has a truthy value, 'null' or 'undefined' the variable
  will reset to @basePollingInterval.

  Note: this function is used to gradually increase the polling interval
  if there aren't new notes coming from the server
  ###
  setPollingInterval: (shouldReset = true) ->
    nthInterval = @basePollingInterval * Math.pow(2, @maxPollingSteps - 1)
    if shouldReset
      @pollingInterval = @basePollingInterval
    else if @pollingInterval < nthInterval
      @pollingInterval *= 2

    @initRefresh()

  ###
  Render note in main comments area.

  Note: for rendering inline notes use renderDiscussionNote
  ###
  renderNote: (note) ->
    unless note.valid
      if note.award
        new Flash('You have already awarded this emoji!', 'alert')
      return

    if note.award
      votesBlock = $('.js-awards-block').eq 0
      gl.awardsHandler.addAwardToEmojiBar votesBlock, note.name
      gl.awardsHandler.scrollToAwards()

    # render note if it not present in loaded list
    # or skip if rendered
    else if @isNewNote(note)
      @note_ids.push(note.id)

      $notesList = $('ul.main-notes-list')

      $notesList
        .append(note.html)
        .syntaxHighlight()

      # Update datetime format on the recent note
      gl.utils.localTimeAgo($notesList.find("#note_#{note.id} .js-timeago"), false)

      @initTaskList()
      @updateNotesCount(1)


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
    return unless @isNewNote(note)

    @note_ids.push(note.id)
    form = $("#new-discussion-note-form-#{note.discussion_id}")
    if note.original_discussion_id? and form.length is 0
      form = $("#new-discussion-note-form-#{note.original_discussion_id}")
    row = form.closest("tr")
    note_html = $(note.html)
    note_html.syntaxHighlight()

    # is this the first note of discussion?
    discussionContainer = $(".notes[data-discussion-id='" + note.discussion_id + "']")
    if note.original_discussion_id? and discussionContainer.length is 0
      discussionContainer = $(".notes[data-discussion-id='" + note.original_discussion_id + "']")
    if discussionContainer.length is 0
      # insert the note and the reply button after the temp row
      row.after note.discussion_html

      # remove the note (will be added again below)
      row.next().find(".note").remove()

      # Before that, the container didn't exist
      discussionContainer = $(".notes[data-discussion-id='" + note.discussion_id + "']")

      # Add note to 'Changes' page discussions
      discussionContainer.append note_html

      # Init discussion on 'Discussion' page if it is merge request page
      if $('body').attr('data-page').indexOf('projects:merge_request') is 0
        $('ul.main-notes-list')
          .append(note.discussion_with_diff_html)
          .syntaxHighlight()
    else
      # append new note to all matching discussions
      discussionContainer.append note_html

    gl.utils.localTimeAgo($('.js-timeago', note_html), false)

    @updateNotesCount(1)

  ###
  Called in response the main target form has been successfully submitted.

  Removes any errors.
  Resets text and preview.
  Resets buttons.
  ###
  resetMainTargetForm: (e) =>
    form = $(".js-main-target-form")

    # remove validation errors
    form.find(".js-errors").remove()

    # reset text and preview
    form.find(".js-md-write-button").click()
    form.find(".js-note-text").val("").trigger "input"

    form.find(".js-note-text").data("autosave").reset()

    @updateTargetButtons(e)

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

    # Set a global clone of the form for later cloning
    @formClone = form.clone()

    # show the form
    @setupNoteForm(form)

    # fix classes
    form.removeClass "js-new-note-form"
    form.addClass "js-main-target-form"

    form.find("#note_line_code").remove()
    form.find("#note_position").remove()
    form.find("#note_type").remove()

    @parentTimeline = form.parents('.timeline')

  ###
  General note form setup.

  deactivates the submit button when text is empty
  hides the preview button when text is empty
  setup GFM auto complete
  show the form
  ###
  setupNoteForm: (form) ->
    new GLForm form

    textarea = form.find(".js-note-text")

    new Autosave textarea, [
      "Note"
      form.find("#note_noteable_type").val()
      form.find("#note_noteable_id").val()
      form.find("#note_commit_id").val()
      form.find("#note_type").val()
      form.find("#note_line_code").val()
      form.find("#note_position").val()
    ]

  ###
  Called in response to the new note form being submitted

  Adds new note to list.
  ###
  addNote: (xhr, note, status) =>
    @renderNote(note)

  addNoteError: (xhr, note, status) =>
    new Flash('Your comment could not be submitted! Please check your network connection and try again.', 'alert', @parentTimeline)

  ###
  Called in response to the new note form being submitted

  Adds new note to list.
  ###
  addDiscussionNote: (xhr, note, status) =>
    @renderDiscussionNote(note)

    # cleanup after successfully creating a diff/discussion note
    @removeDiscussionNoteForm($(xhr.target))

  ###
  Called in response to the edit note form being submitted

  Updates the current note field.
  ###
  updateNote: (_xhr, note, _status) =>
    # Convert returned HTML to a jQuery object so we can modify it further
    $html = $(note.html)

    gl.utils.localTimeAgo($('.js-timeago', $html))

    $html.syntaxHighlight()
    $html.find('.js-task-list-container').taskList('enable')

    # Find the note's `li` element by ID and replace it with the updated HTML
    $note_li = $('.note-row-' + note.id)
    $note_li.replaceWith($html)

  ###
  Called in response to clicking the edit note link

  Replaces the note text with the note edit form
  Adds a data attribute to the form with the original content of the note for cancellations
  ###
  showEditForm: (e, scrollTo, myLastNote) ->
    e.preventDefault()
    note = $(this).closest(".note")
    note.addClass "is-editting"
    form = note.find(".note-edit-form")

    form.addClass('current-note-edit-form')

    # Show the attachment delete link
    note.find(".js-note-attachment-delete").show()

    done = ($noteText) ->
      # Neat little trick to put the cursor at the end
      noteTextVal = $noteText.val()
      # Store the original note text in a data attribute to retrieve if a user cancels edit.
      form.find('form.edit-note').data 'original-note', noteTextVal
      $noteText.val('').val(noteTextVal);

    new GLForm form
    if scrollTo? and myLastNote?
      # scroll to the bottom
      # so the open of the last element doesn't make a jump
      $('html, body').scrollTop($(document).height());
      $('html, body').animate({
        scrollTop: myLastNote.offset().top - 150
      }, 500, ->
        $noteText = form.find(".js-note-text")
        $noteText.focus()
        done($noteText)
      );
    else
      $noteText = form.find('.js-note-text')
      $noteText.focus()
      done($noteText)

  ###
  Called in response to clicking the edit note link

  Hides edit form and restores the original note text to the editor textarea.
  ###
  cancelEdit: (e) =>
    e.preventDefault()
    note = $(e.target).closest('.note')
    @removeNoteEditForm(note)

  removeNoteEditForm: (note) ->
    form = note.find(".current-note-edit-form")
    note.removeClass "is-editting"
    form.removeClass("current-note-edit-form")
    # Replace markdown textarea text with original note text.
    form.find(".js-note-text").val(form.find('form.edit-note').data('original-note'))

  ###
  Called in response to deleting a note of any kind.

  Removes the actual note from view.
  Removes the whole discussion if the last note is being removed.
  ###
  removeNote: (e) =>
    noteId = $(e.currentTarget)
               .closest(".note")
               .attr("id")

    # A same note appears in the "Discussion" and in the "Changes" tab, we have
    # to remove all. Using $(".note[id='noteId']") ensure we get all the notes,
    # where $("#noteId") would return only one.
    $(".note[id='#{noteId}']").each (i, el) =>
      note  = $(el)
      notes = note.closest(".notes")

      # check if this is the last note for this line
      if notes.find(".note").length is 1

        # "Discussions" tab
        notes.closest(".timeline-entry").remove()

        # "Changes" tab / commit view
        notes.closest("tr").remove()

      note.remove()

    # Decrement the "Discussions" counter only once
    @updateNotesCount(-1)

  ###
  Called in response to clicking the delete attachment link

  Removes the attachment wrapper view, including image tag if it exists
  Resets the note editing form
  ###
  removeAttachment: ->
    note = $(this).closest(".note")
    note.find(".note-attachment").remove()
    note.find(".note-body > .note-text").show()
    note.find(".note-header").show()
    note.find(".current-note-edit-form").remove()

  ###
  Called when clicking on the "reply" button for a diff line.

  Shows the note form below the notes.
  ###
  replyToDiscussionNote: (e) =>
    form = @formClone.clone()
    replyLink = $(e.target).closest(".js-discussion-reply-button")
    replyLink.hide()

    # insert the form after the button
    replyLink.after form

    # show the form
    @setupDiscussionNoteForm(replyLink, form)

  ###
  Shows the diff or discussion form and does some setup on it.

  Sets some hidden fields in the form.

  Note: dataHolder must have the "discussionId", "lineCode", "noteableType"
  and "noteableId" data attributes set.
  ###
  setupDiscussionNoteForm: (dataHolder, form) =>
    # setup note target
    form.attr 'id', "new-discussion-note-form-#{dataHolder.data("discussionId")}"
    form.attr "data-line-code", dataHolder.data("lineCode")
    form.find("#note_type").val dataHolder.data("noteType")
    form.find("#line_type").val dataHolder.data("lineType")
    form.find("#note_commit_id").val dataHolder.data("commitId")
    form.find("#note_line_code").val dataHolder.data("lineCode")
    form.find("#note_position").val dataHolder.attr("data-position")
    form.find("#note_noteable_type").val dataHolder.data("noteableType")
    form.find("#note_noteable_id").val dataHolder.data("noteableId")
    form.find('.js-note-discard')
        .show()
        .removeClass('js-note-discard')
        .addClass('js-close-discussion-note-form')
        .text(form.find('.js-close-discussion-note-form').data('cancel-text'))
    @setupNoteForm form
    form.find(".js-note-text").focus()
    form
      .removeClass('js-main-target-form')
      .addClass("discussion-form js-discussion-note-form")

  ###
  Called when clicking on the "add a comment" button on the side of a diff line.

  Inserts a temporary row for the form below the line.
  Sets up the form and shows it.
  ###
  addDiffNote: (e) =>
    e.preventDefault()
    $link = $(e.currentTarget)
    row = $link.closest("tr")
    nextRow = row.next()
    hasNotes = nextRow.is(".notes_holder")
    addForm = false
    targetContent = ".notes_content"
    rowCssToAdd = "<tr class=\"notes_holder js-temp-notes-holder\"><td class=\"notes_line\" colspan=\"2\"></td><td class=\"notes_content\"></td></tr>"

    # In parallel view, look inside the correct left/right pane
    if @isParallelView()
      lineType = $link.data("lineType")
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
      newForm = @formClone.clone()
      newForm.appendTo row.next().find(targetContent)

      # show the form
      @setupDiscussionNoteForm $link, newForm

  ###
  Called in response to "cancel" on a diff note form.

  Shows the reply button again.
  Removes the form and if necessary it's temporary row.
  ###
  removeDiscussionNoteForm: (form)->
    row = form.closest("tr")

    glForm = form.data 'gl-form'
    glForm.destroy()

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
    form = $(e.target).closest(".js-discussion-note-form")
    @removeDiscussionNoteForm(form)

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

  updateCloseButton: (e) =>
    textarea = $(e.target)
    form = textarea.parents('form')
    closebtn = form.find('.js-note-target-close')
    closebtn.text(closebtn.data('original-text'))

  updateTargetButtons: (e) =>
    textarea = $(e.target)
    form = textarea.parents('form')
    reopenbtn = form.find('.js-note-target-reopen')
    closebtn = form.find('.js-note-target-close')
    discardbtn = form.find('.js-note-discard')

    if textarea.val().trim().length > 0
      reopentext = reopenbtn.data('alternative-text')
      closetext = closebtn.data('alternative-text')

      if reopenbtn.text() isnt reopentext
        reopenbtn.text(reopentext)

      if closebtn.text() isnt closetext
        closebtn.text(closetext)

      if reopenbtn.is(':not(.btn-comment-and-reopen)')
        reopenbtn.addClass('btn-comment-and-reopen')

      if closebtn.is(':not(.btn-comment-and-close)')
        closebtn.addClass('btn-comment-and-close')

      if discardbtn.is(':hidden')
        discardbtn.show()
    else
      reopentext = reopenbtn.data('original-text')
      closetext = closebtn.data('original-text')

      if reopenbtn.text() isnt reopentext
        reopenbtn.text(reopentext)

      if closebtn.text() isnt closetext
        closebtn.text(closetext)

      if reopenbtn.is('.btn-comment-and-reopen')
        reopenbtn.removeClass('btn-comment-and-reopen')

      if closebtn.is('.btn-comment-and-close')
        closebtn.removeClass('btn-comment-and-close')

      if discardbtn.is(':visible')
        discardbtn.hide()

  initTaskList: ->
    @enableTaskList()
    $(document).on 'tasklist:changed', '.note .js-task-list-container', @updateTaskList

  enableTaskList: ->
    $('.note .js-task-list-container').taskList('enable')

  updateTaskList: ->
    $('form', this).submit()

  updateNotesCount: (updateCount) ->
    @notesCountBadge.text(parseInt(@notesCountBadge.text()) + updateCount)
