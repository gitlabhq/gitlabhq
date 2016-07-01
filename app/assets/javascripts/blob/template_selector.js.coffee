class @TemplateSelector
  constructor: (opts = {}) ->
    {
      @dropdown,
      @data,
      @pattern,
      @wrapper,
      @editor,
      @fileEndpoint,
      @$input = $('#file_name')
    } = opts

    @buildDropdown()
    @bindEvents()
    @onFilenameUpdate()

  buildDropdown: ->
    @dropdown.glDropdown(
      data: @data,
      filterable: true,
      selectable: true,
      toggleLabel: @toggleLabel,
      search:
        fields: ['name']
      clicked: @onClick
      text: (item) ->
        item.name
    )

  bindEvents: ->
    @$input.on('keyup blur', (e) =>
      @onFilenameUpdate()
    )

  toggleLabel: (item) ->
    item.name

  onFilenameUpdate: ->
    return unless @$input.length

    filenameMatches = @pattern.test(@$input.val().trim())

    if not filenameMatches
      @wrapper.addClass('hidden')
      return

    @wrapper.removeClass('hidden')

  onClick: (item, el, e) =>
    e.preventDefault()
    @requestFile(item)

  requestFile: (item) ->
    # To be implemented on the extending class
    # e.g.
    # Api.gitignoreText item.name, @requestFileSuccess.bind(@)

  requestFileSuccess: (file) ->
    @editor.setValue(file.content, 1)
    @editor.focus()
