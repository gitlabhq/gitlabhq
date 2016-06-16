class @BlobGitignoreSelectors
  constructor: (opts) ->
    {
      @$dropdowns = $('.js-gitignore-selector')
      @editor
    } = opts

    @$dropdowns.each (i, dropdown) =>
      $dropdown = $(dropdown)

      new BlobGitignoreSelector(
        pattern: /(.gitignore)/,
        data: $dropdown.data('data'),
        wrapper: $dropdown.closest('.js-gitignore-selector-wrap'),
        dropdown: $dropdown,
        editor: @editor
      )
