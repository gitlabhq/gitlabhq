class Project
  constructor: ->
    $('.project-edit-container').on 'ajax:before', =>
      $('.project-edit-container').hide()
      $('.save-project-loader').show()

    @initEvents()


  initEvents: ->
    disableButtonIfEmptyField '#project_name', '.project-submit'

    auto_init_checked = $('#project_auto_init').is(':checked')

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

    $('#project_import_url').change ->
      if ($(this).val().length > 0)
        $('#project_auto_init').attr('disabled', 'disabled')
        $('#project_auto_init').attr('checked', false)
      else
        $('#project_auto_init').removeAttr('disabled')
        if (auto_init_checked)
          $('#project_auto_init').attr('checked', true)
        else 
          $('#project_auto_init').attr('checked', false)


@Project = Project

$ ->
  # Git clone panel switcher
  scope = $ '.git-clone-holder'
  if scope.length > 0
    $('a, button', scope).click ->
      $('a, button', scope).removeClass 'active'
      $(@).addClass 'active'
      $('#project_clone', scope).val $(@).data 'clone'
      $(".clone").text("").append $(@).data 'clone'

  # Ref switcher
  $('.project-refs-select').on 'change', ->
    $(@).parents('form').submit()

  $('.hide-no-ssh-message').on 'click', (e) ->
    path = '/'
    $.cookie('hide_no_ssh_message', 'false', { path: path })
    $(@).parents('.no-ssh-key-message').hide()
    e.preventDefault()
