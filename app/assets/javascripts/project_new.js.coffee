class @ProjectNew
  constructor: ->
    $('.project-edit-container').on 'ajax:before', =>
      $('.project-edit-container').hide()
      $('.save-project-loader').show()

    @initEvents()


  initEvents: ->
    disableButtonIfEmptyField '#project_name', '.project-submit'

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
