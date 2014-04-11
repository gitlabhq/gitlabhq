class ProjectTemplate
  constructor: ->

    disableButtonIfEmptyField '#project_template_name', '.new-project-template-submit'

    $('.new-project-template-submit').click ->
      $('.save-project-template-loader').removeClass('hidden')
      $('.new-project-template-container').addClass('hidden')

    $('.js-choose-project-template-button').click ->
      form = $(@).closest("form")
      form.find(".js-project-template-upload-input").click()

    $('.js-project-template-upload-input').change ->
      form = $(@).closest("form")
      filename = $(@).val().replace(/^.*[\\\/]/, '')
      form.find(".js-project-template-upload-filename").text(filename)

@ProjectTemplate = ProjectTemplate
