class Wall
  constructor: (project_id) ->
    @project_id = project_id
    @note_ids = []
    @getContent()
    @initRefresh()
    @initForm()
  
  # 
  # Gets an initial set of notes.
  # 
  getContent: ->
    Api.notes @project_id, (notes) =>
      $.each notes, (i, note) =>
        # render note if it not present in loaded list
        # or skip if rendered
        if $.inArray(note.id, @note_ids) == -1
          @note_ids.push(note.id)
          @renderNote(note)
          @scrollDown()
          $("abbr.timeago").timeago()

  initRefresh: ->
    setInterval =>
      @refresh()
    , 10000

  refresh: ->
    @getContent()

  scrollDown: ->
    notes = $('ul.notes')
    $('body, html').scrollTop(notes.height())

  initForm: ->
    form = $('.wall-note-form')
    form.find("#target_type").val('wall')

    form.on 'ajax:success', =>
      @refresh()
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
    template = @noteTemplate()
    template = template.replace('{{author_name}}', note.author.name)
    template = template.replace(/{{created_at}}/g, note.created_at)
    template = template.replace('{{text}}', simpleFormat(note.body))

    if note.attachment
      file = '<i class="icon-paper-clip"/><a href="' + gon.relative_url_root + '/files/note/' + note.id + '/' + note.attachment + '">' + note.attachment + '</a>'
    else
      file = ''
    template = template.replace('{{file}}', file)


    $('ul.notes').append(template)

  noteTemplate: ->
    return '<li>
      <strong class="wall-author">{{author_name}}</strong>
      <span class="wall-text">
        {{text}}
        <span class="wall-file">{{file}}</span>
      </span>
      <abbr class="timeago" title="{{created_at}}">{{created_at}}</abbr>
    </li>'

@Wall = Wall
