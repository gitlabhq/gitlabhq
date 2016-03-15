class @ProjectNew
  constructor: ->
    $('.project-edit-container').on 'ajax:before', =>
      $('.project-edit-container').hide()
      $('.save-project-loader').show()
    @toggleSettings()
    @toggleSettingsOnclick()


  toggleSettings: ->
    checked = $("#project_builds_enabled").prop("checked")
    if checked
      $('.builds-feature').show()
    else
      $('.builds-feature').hide()

  toggleSettingsOnclick: ->
    $("#project_builds_enabled").on 'click', @toggleSettings
