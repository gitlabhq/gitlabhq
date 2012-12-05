@NoteList =
  notes_path: null
  target_params: null
  target_id: 0
  target_type: null
  top_id: 0
  bottom_id: 0
  loading_more_disabled: false
  reversed: false
  init: (tid, tt, path) ->
    @notes_path = path + ".js"
    @target_id = tid
    @target_type = tt
    @reversed = $("#notes-list").is(".reversed")
    @target_params = "target_type=" + @target_type + "&target_id=" + @target_id

    # get initial set of notes
    @getContent()
    $("#notes-list, #new-notes-list").on "ajax:success", ".delete-note", ->
      $(this).closest("li").fadeOut ->
        $(this).remove()
        NoteList.updateVotes()


    $(".note-form-holder").on "ajax:before", ->
      $(".submit_note").disable()

    $(".note-form-holder").on "ajax:complete", ->
      $(".submit_note").enable()
      $("#preview-note").hide()
      $("#note_note").show()

    disableButtonIfEmptyField ".note-text", ".submit_note"
    $("#note_attachment").change (e) ->
      val = $(".input-file").val()
      filename = val.replace(/^.*[\\\/]/, "")
      $(".file_name").text filename

    if @reversed
      textarea = $(".note-text")
      $(".note_advanced_opts").hide()
      textarea.css "height", "40px"
      textarea.on "focus", ->
        $(this).css "height", "80px"
        $(".note_advanced_opts").show()


    # Setup note preview
    $(document).on "click", "#preview-link", (e) ->
      $("#preview-note").text "Loading..."
      $(this).text (if $(this).text() is "Edit" then "Preview" else "Edit")
      note_text = $("#note_note").val()
      if note_text.trim().length is 0
        $("#preview-note").text "Nothing to preview."
      else
        $.post($(this).attr("href"),
          note: note_text
        ).success (data) ->
          $("#preview-note").html data

      $("#preview-note, #note_note").toggle()
      e.preventDefault()



  ###
  Handle loading the initial set of notes.
  And set up loading more notes when scrolling to the bottom of the page.
  ###

  ###
  Gets an inital set of notes.
  ###
  getContent: ->
    $.ajax
      type: "GET"
      url: @notes_path
      data: @target_params
      complete: ->
        $(".notes-status").removeClass "loading"

      beforeSend: ->
        $(".notes-status").addClass "loading"

      dataType: "script"



  ###
  Called in response to getContent().
  Replaces the content of #notes-list with the given html.
  ###
  setContent: (first_id, last_id, html) ->
    @top_id = first_id
    @bottom_id = last_id
    $("#notes-list").html html

    # init infinite scrolling
    @initLoadMore()

    # init getting new notes
    @initRefreshNew()  if @reversed


  ###
  Handle loading more notes when scrolling to the bottom of the page.
  The id of the last note in the list is in this.bottom_id.

  Set up refreshing only new notes after all notes have been loaded.
  ###

  ###
  Initializes loading more notes when scrolling to the bottom of the page.
  ###
  initLoadMore: ->
    $(document).endlessScroll
      bottomPixels: 400
      fireDelay: 1000
      fireOnce: true
      ceaseFire: ->
        NoteList.loading_more_disabled

      callback: (i) ->
        NoteList.getMore()



  ###
  Gets an additional set of notes.
  ###
  getMore: ->

    # only load more notes if there are no "new" notes
    $(".loading").show()
    $.ajax
      type: "GET"
      url: @notes_path
      data: @target_params + "&loading_more=1&" + ((if @reversed then "before_id" else "after_id")) + "=" + @bottom_id
      complete: ->
        $(".notes-status").removeClass "loading"

      beforeSend: ->
        $(".notes-status").addClass "loading"

      dataType: "script"



  ###
  Called in response to getMore().
  Append notes to #notes-list.
  ###
  appendMoreNotes: (id, html) ->
    unless id is @bottom_id
      @bottom_id = id
      $("#notes-list").append html


  ###
  Called in response to getMore().
  Disables loading more notes when scrolling to the bottom of the page.
  Initalizes refreshing new notes.
  ###
  finishedLoadingMore: ->
    @loading_more_disabled = true

    # from now on only get new notes
    @initRefreshNew()  unless @reversed

    # make sure we are up to date
    @updateVotes()


  ###
  Handle refreshing and adding of new notes.

  New notes are all notes that are created after the site has been loaded.
  The "old" notes are in #notes-list the "new" ones will be in #new-notes-list.
  The id of the last "old" note is in this.bottom_id.
  ###

  ###
  Initializes getting new notes every n seconds.
  ###
  initRefreshNew: ->
    setInterval "NoteList.getNew()", 10000


  ###
  Gets the new set of notes.
  ###
  getNew: ->
    $.ajax
      type: "GET"
      url: @notes_path
      data: @target_params + "&loading_new=1&after_id=" + ((if @reversed then @top_id else @bottom_id))
      dataType: "script"



  ###
  Called in response to getNew().
  Replaces the content of #new-notes-list with the given html.
  ###
  replaceNewNotes: (html) ->
    $("#new-notes-list").html html
    @updateVotes()


  ###
  Adds a single note to #new-notes-list.
  ###
  appendNewNote: (id, html) ->
    if @reversed
      $("#new-notes-list").prepend html
    else
      $("#new-notes-list").append html
    @updateVotes()


  ###
  Recalculates the votes and updates them (if they are displayed at all).

  Assumes all relevant notes are displayed (i.e. there are no more notes to
  load via getMore()).
  Might produce inaccurate results when not all notes have been loaded and a
  recalculation is triggered (e.g. when deleting a note).
  ###
  updateVotes: ->
    votes = $("#votes .votes")
    notes = $("#notes-list, #new-notes-list").find(".note .vote")

    # only update if there is a vote display
    if votes.size()
      upvotes = notes.filter(".upvote").size()
      downvotes = notes.filter(".downvote").size()
      votesCount = upvotes + downvotes
      upvotesPercent = (if votesCount then (100.0 / votesCount * upvotes) else 0)
      downvotesPercent = (if votesCount then (100.0 - upvotesPercent) else 0)

      # change vote bar lengths
      votes.find(".bar-success").css "width", upvotesPercent + "%"
      votes.find(".bar-danger").css "width", downvotesPercent + "%"

      # replace vote numbers
      votes.find(".upvotes").text votes.find(".upvotes").text().replace(/\d+/, upvotes)
      votes.find(".downvotes").text votes.find(".downvotes").text().replace(/\d+/, downvotes)

@PerLineNotes = init: ->

  ###
  Called when clicking on the "add note" or "reply" button for a diff line.

  Shows the note form below the line.
  Sets some hidden fields in the form.
  ###
  $(".diff_file_content").on "click", ".line_note_link, .line_note_reply_link", (e) ->
    form = $(".per_line_form")
    $(this).closest("tr").after form
    form.find("#note_line_code").val $(this).data("lineCode")
    form.show()
    e.preventDefault()

  disableButtonIfEmptyField ".line-note-text", ".submit_inline_note"

  ###
  Called in response to successfully deleting a note on a diff line.

  Removes the actual note from view.
  Removes the reply button if the last note for that line has been removed.
  ###
  $(".diff_file_content").on "ajax:success", ".delete-note", ->
    trNote = $(this).closest("tr")
    trNote.fadeOut ->
      $(this).remove()


    # check if this is the last note for this line
    # elements must really be removed for this to work reliably
    trLine = trNote.prev()
    trRpl = trNote.next()
    if trLine.is(".line_holder") and trRpl.is(".reply")
      trRpl.fadeOut ->
        $(this).remove()


