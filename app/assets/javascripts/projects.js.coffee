window.Projects = ->
  $('.new_project, .edit_project').on 'ajax:before', ->
    $('.project_new_holder, .project_edit_holder').hide()
    $('.save-project-loader').show()

  $('form #project_default_branch').chosen()
  disableButtonIfEmptyField '#project_name', '.project-submit'

$ ->
  # Git clone panel switcher
  scope = $ '.project_clone_holder'
  if scope.length > 0
    $('a, button', scope).click ->
      $('a, button', scope).removeClass 'active'
      $(@).addClass 'active'
      $('#project_clone', scope).val $(@).data 'clone'

  # Ref switcher
  $('.project-refs-select').on 'change', ->
    $(@).parents('form').submit()

  $('#project_issues_enabled').change ->
    if ($(this).is(':checked') == true)
      $('#project_issues_tracker').removeAttr('disabled')
    else
      $('#project_issues_tracker').attr('disabled', 'disabled')

    $('#project_issues_tracker').change()

  $('#project_issues_tracker').change ->
    if ($(this).val() == gon.default_issues_tracker || $(this).is(':disabled'))
      $('#project_issues_tracker_id').attr('disabled', 'disabled')
    else
      $('#project_issues_tracker_id').removeAttr('disabled')

