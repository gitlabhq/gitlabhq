class @BlobLicenseSelectors
  constructor: (opts) ->
    {
      @$dropdowns = $('.js-license-selector')
      @editor
    } = opts

    @$dropdowns.each (i, dropdown) =>
      $dropdown = $(dropdown)

      new BlobLicenseSelector(
        pattern: /^(.+\/)?(licen[sc]e|copying)($|\.)/i,
        data: $dropdown.data('data'),
        wrapper: $dropdown.closest('.js-license-selector-wrap'),
        dropdown: $dropdown,
        editor: @editor
      )
