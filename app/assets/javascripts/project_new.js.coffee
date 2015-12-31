class @ProjectNew
  constructor: ->
    $('.project-edit-container').on 'ajax:before', =>
      $('.project-edit-container').hide()
      $('.save-project-loader').show()
    @toggleSettings()


  toggleSettings: ->
    checked = $("#project_merge_requests_enabled").prop("checked")
    if checked
      $('.merge-request-feature').show()
    else
      $('.merge-request-feature').hide()
