#= require blob/template_selector

class @BlobLicenseSelector extends TemplateSelector
  requestFile: (query) ->
    data =
      project: @dropdown.data('project')
      fullname: @dropdown.data('fullname')

    Api.licenseText query.id, data, @requestFileSuccess.bind(@)
