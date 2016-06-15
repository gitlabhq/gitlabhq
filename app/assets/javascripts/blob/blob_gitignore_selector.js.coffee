#= require blob/template_selector

class @BlobGitignoreSelector extends TemplateSelector
  requestFile: (query) ->
    Api.gitignoreText query.name, @requestFileSuccess.bind(@)
