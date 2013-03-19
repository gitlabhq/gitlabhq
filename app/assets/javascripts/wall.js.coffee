@Wall =
  note_ids: []
  notes_path: null
  notes_params: null
  project_id: null

  init: (project_id) ->
    Wall.project_id = project_id
    Wall.notes_path = "/api/" + gon.api_version + "/projects/" + project_id + "/notes.json"
    Wall.getContent()
    Wall.initRefresh()
    Wall.initForm()
  
  # 
  # Gets an initial set of notes.
  # 
  getContent: ->
    $.ajax
      url: Wall.notes_path,
      data:
        private_token: gon.api_token
        gfm: true
        recent: true
      dataType: "json"
      success: (notes) ->
        notes.sort (a, b) ->
          return a.id - b.id
        $.each notes, (i, note)->
          if $.inArray(note.id, Wall.note_ids) == -1
            Wall.note_ids.push(note.id)
            Wall.renderNote(note)
            Wall.scrollDown()

      complete: ->
        $('.js-notes-busy').removeClass("loading")
      beforeSend: ->
        $('.js-notes-busy').addClass("loading")

  renderNote: (note) ->
    author = '<strong class="wall-author">' + note.author.name + '</strong>'
    body = '<span class="wall-text">' + note.body + '</span>'
    file = ''

    if note.attachment
      file = '<span class="wall-file"><a href="/files/note/' + note.id + '/' + note.attachment + '">' + note.attachment + '</a></span>'
    
    html = '<li>' + author + body + file + '</li>'

    $('ul.notes').append(html)

  initRefresh: ->
    setInterval("Wall.refresh()", 10000)

  refresh: ->
    Wall.getContent()

  scrollDown: ->
    notes = $('ul.notes')
    $('body').scrollTop(notes.height())

  initForm: ->
    form = $('.new_note')
    form.find("#target_type").val('wall')

    # remove unnecessary fields and buttons
    form.find("#note_line_code").remove()
    form.find(".js-close-discussion-note-form").remove()
    form.find('.js-notify-commit-author').remove()

    form.on 'ajax:success', ->
      Wall.refresh()
      form.find(".js-note-text").val("").trigger("input")
    
    form.on 'ajax:complete', ->
      form.find(".js-comment-button").removeAttr('disabled')
      form.find(".js-comment-button").removeClass('disabled')

    form.on "click", ".js-choose-note-attachment-button", ->
      form.find(".js-note-attachment-input").click()

    form.on "change", ".js-note-attachment-input", ->
      filename = $(this).val().replace(/^.*[\\\/]/, '')
      form.find(".js-attachment-filename").text(filename)
    
    form.show()
