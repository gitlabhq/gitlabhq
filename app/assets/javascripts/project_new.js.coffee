class @ProjectNew
  constructor: ->
    $('.project-edit-container').on 'ajax:before', =>
      $('.project-edit-container').hide()
      $('.save-project-loader').show()
    @toggleSettings()
    @toggleSettingsOnclick()


  toggleSettings: =>
    @_showOrHide('#project_builds_enabled', '.builds-feature')
    @_showOrHide('#project_merge_requests_enabled', '.merge-requests-feature')

  toggleSettingsOnclick: ->
    $('#project_builds_enabled, #project_merge_requests_enabled').on 'click', @toggleSettings

  _showOrHide: (checkElement, container) ->
    $container = $(container)

    if $(checkElement).prop('checked')
      $container.show()
    else
      $container.hide()
