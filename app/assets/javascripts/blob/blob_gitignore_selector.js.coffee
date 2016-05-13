class @BlobGitignoreSelector
  constructor: (opts) ->
    {
      @dropdown
      @editor
      @$wrapper        = @dropdown.closest('.gitignore-selector')
      @$filenameInput  = $('#file_name')
      @data           = @dropdown.data('filenames')
    } = opts

    @dropdown.glDropdown(
      data: @data,
      filterable: true,
      selectable: true,
      search:
        fields: ['name']
      clicked: @onClick
      text: (gitignore) ->
        gitignore.name
    )

    @toggleGitignoreSelector()
    @bindEvents()

  bindEvents: ->
    @$filenameInput
      .on 'keyup blur', (e) =>
        @toggleGitignoreSelector()

  toggleGitignoreSelector: ->
    filename = @$filenameInput.val() or $('.editor-file-name').text().trim()
    @$wrapper.toggleClass 'hidden', filename isnt '.gitignore'

  onClick: (item, el, e) =>
    e.preventDefault()
    @requestIgnoreFile(item.name)

  requestIgnoreFile: (name) ->
    Api.gitignoreText name, @requestIgnoreFileSuccess.bind(@)

  requestIgnoreFileSuccess: (gitignore) ->
    @editor.setValue(gitignore.content, 1)
    @editor.focus()

class @BlobGitignoreSelectors
  constructor: (opts) ->
    {
      @$dropdowns = $('.js-gitignore-selector')
      @editor
    } = opts

    @$dropdowns.each (i, dropdown) =>
      $dropdown = $(dropdown)

      new BlobGitignoreSelector(
        dropdown: $dropdown,
        editor: @editor
      )
