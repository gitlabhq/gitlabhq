class @BlobLicenseSelector
  licenseRegex: /^(.+\/)?(licen[sc]e|copying)($|\.)/i

  constructor: (editor) ->
    @$licenseSelector = $('.js-license-selector')
    $fileNameInput = $('#file_name')

    initialFileNameValue = if $fileNameInput.length
      $fileNameInput.val()
    else if $('.editor-file-name').length
      $('.editor-file-name').text().trim()

    @toggleLicenseSelector(initialFileNameValue)

    if $fileNameInput
      $fileNameInput.on 'keyup blur', (e) =>
        @toggleLicenseSelector($(e.target).val())

    $('select.license-select').on 'change', (e) ->
      data =
        project: $(this).data('project')
        fullname: $(this).data('fullname')
      Api.licenseText $(this).val(), data, (license) ->
        editor.setValue(license.content, -1)

  toggleLicenseSelector: (fileName) =>
    if @licenseRegex.test(fileName)
      @$licenseSelector.show()
    else
      @$licenseSelector.hide()
