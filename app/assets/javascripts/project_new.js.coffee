class @ProjectNew
  constructor: ->
    $('.project-edit-container').on 'ajax:before', =>
      $('.project-edit-container').hide()
      $('.save-project-loader').show()
    @toggleSettings()
    @toggleSettingsOnclick()


  toggleSettings: ->
    checked = $("#project_merge_requests_enabled").prop("checked")
    if checked
      $('.merge-request-feature').show()
    else
      $('.merge-request-feature').hide()
    checked = $("#project_issues_enabled").prop("checked")
    if checked
      $('.issues-feature').show()
    else
      $('.issues-feature').hide()
    checked = $("#project_builds_enabled").prop("checked")
    if checked
      $('.builds-feature').show()
    else
      $('.builds-feature').hide()

  toggleSettingsOnclick: ->
    $("#project_merge_requests_enabled").on 'click', @toggleSettings
    $("#project_issues_enabled").on 'click', @toggleSettings
    $("#project_builds_enabled").on 'click', @toggleSettings
