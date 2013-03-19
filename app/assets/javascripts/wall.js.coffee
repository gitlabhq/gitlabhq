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

      complete: ->
        $('.js-notes-busy').removeClass("loading")
      beforeSend: ->
        $('.js-notes-busy').addClass("loading")

  renderNote: (note) ->
    author = '<strong>' + note.author.name + ': &nbsp;</strong>'
    html = '<li>' + author + note.body + '</li>'
    $('ul.notes').append(html)

  initRefresh: ->
    setInterval("Wall.refresh()", 10000)

  refresh: ->
    Wall.getContent()
