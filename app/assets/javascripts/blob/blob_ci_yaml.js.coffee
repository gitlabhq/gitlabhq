#= require blob/template_selector

class @BlobCiYamlSelector extends TemplateSelector
  requestFile: (query) ->
    Api.gitlabCiYml query.name, @requestFileSuccess.bind(@)

class @BlobCiYamlSelectors
  constructor: (opts) ->
    {
      @$dropdowns = $('.js-gitlab-ci-yml-selector')
      @editor
    } = opts

    @$dropdowns.each (i, dropdown) =>
      $dropdown = $(dropdown)

      new BlobCiYamlSelector(
        pattern: /(.gitlab-ci.yml)/,
        data: $dropdown.data('data'),
        wrapper: $dropdown.closest('.js-gitlab-ci-yml-selector-wrap'),
        dropdown: $dropdown,
        editor: @editor
      )
