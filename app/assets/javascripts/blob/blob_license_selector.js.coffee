class @BlobLicenseSelector
  licenseRegex: /^(.+\/)?(licen[sc]e|copying)($|\.)/i

  constructor: (editor)->
    self = this
    @licenseSelector = $('.js-license-selector')
    @toggleLicenseSelector($('#file_name').val())

    $('#file_name').on 'input', ->
      self.toggleLicenseSelector($(this).val())

    $('select.license-select').select2(
      width: 'resolve'
      dropdownAutoWidth: true
      placeholder: 'Choose a license template'
    ).on 'change', (e) ->
      Api.licenseText $(this).val(), $(this).data('fullname'), (data) ->
        editor.setValue(data, -1)

  toggleLicenseSelector: (fileName) =>
    if @licenseRegex.test(fileName)
      @licenseSelector.show()
    else
      @licenseSelector.hide()
