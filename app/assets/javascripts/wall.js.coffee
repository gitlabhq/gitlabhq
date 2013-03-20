@Wall =
  note_ids: []
  project_id: null

  init: (project_id) ->
    Wall.project_id = project_id
    Wall.getContent()
    Wall.initRefresh()
    Wall.initForm()
  
  # 
  # Gets an initial set of notes.
  # 
  getContent: ->
    Api.notes Wall.project_id, (notes) ->
      $.each notes, (i, note) ->
        # render note if it not present in loaded list
        # or skip if rendered
        if $.inArray(note.id, Wall.note_ids) == -1
          Wall.note_ids.push(note.id)
          Wall.renderNote(note)
          Wall.scrollDown()
          $("abbr.timeago").timeago()

  initRefresh: ->
    setInterval("Wall.refresh()", 10000)

  refresh: ->
    Wall.getContent()

  scrollDown: ->
    notes = $('ul.notes')
    $('body, html').scrollTop(notes.height())

  initForm: ->
    form = $('.wall-note-form')
    form.find("#target_type").val('wall')

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
    
    form.find('.note_text').keydown (e) ->
      if e.ctrlKey && e.keyCode == 13
        form.find('.js-comment-button').submit()

    form.show()
  
  renderNote: (note) ->
    author = '<strong class="wall-author">' + note.author.name + '</strong>'
    body = '<span class="wall-text">' + linkify(sanitize(note.body)) + '</span>'
    file = ''
    time = '<abbr class="timeago" title="' + note.created_at + '">' + note.created_at + '</time>'

    if note.attachment
      file = '<span class="wall-file"><a href="/files/note/' + note.id + '/' + note.attachment + '">' + note.attachment + '</a></span>'
    
    html = '<li>' + author + body + file + time + '</li>'

    $('ul.notes').append(html)
