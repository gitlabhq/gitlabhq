class @ProjectNew
  constructor: ->
    $('.project-edit-container').on 'ajax:before', =>
      $('.project-edit-container').hide()
      $('.save-project-loader').show()

    @initEvents()


  initEvents: ->
    disableButtonIfEmptyField '#project_name', '.project-submit'

    $("#project_merge_requests_enabled").change ->
      checked = $(this).prop("checked")
      $("#project_merge_requests_template").prop "disabled", not checked
      $("#project_merge_requests_rebase_enabled").prop "disabled", not checked
