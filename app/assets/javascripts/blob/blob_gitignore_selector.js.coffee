class @BlobGitIgnoreSelector
  constructor: (opts) ->
    {
      @dropdown
      @editor
      @wrapper        = @dropdown.parents('.gitignore-selector')
      @fileNameInput  = $('#file_name')
      @data           = @dropdown.data('filenames')
    } = opts

    @dropdown.glDropdown(
      data: @data,
      filterable: true,
      selectable: true,
      search:
        fields: ['text']
      clicked: @onClick.bind(@)
    )

    @toggleGitIgnoreSelector()
    @bindEvents()

  bindEvents: ->
    @fileNameInput
      .on 'keyup blur', (e) =>
        @toggleGitIgnoreSelector()

  toggleGitIgnoreSelector: ->
    filename = @fileNameInput.val() or $('.editor-file-name').text().trim()
    @wrapper.toggleClass 'hidden', filename isnt '.gitignore'

  onClick: (item, el, e) ->
    e.preventDefault()
    @requestIgnoreFile(item.text)

  requestIgnoreFile: (name) ->
    Api.gitIgnoreText name, @requestIgnoreFileSuccess.bind(@)

  requestIgnoreFileSuccess: (gitignore) ->
    @editor.setValue(gitignore.content, -1)

    # Move cursor position to end of file
    row = @editor.session.getLength() - 1
    column = @editor.session.getLine(row).length
    @editor.gotoLine(row + 1, column)
    @editor.focus()

class @BlobGitIgnoreSelectors
  constructor: (opts) ->
    _this = @

    {
      @dropdowns = $('.js-gitignore-selector')
      @editor
    } = opts

    @dropdowns.each ->
      $dropdown = $(@)

      new BlobGitIgnoreSelector(
        dropdown: $dropdown,
        editor: _this.editor
      )
