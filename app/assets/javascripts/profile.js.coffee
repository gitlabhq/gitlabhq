$ ->
  $('.edit_user .application-theme input, .edit_user .code-preview-theme input').click ->
    # Submit the form
    $('.edit_user').submit()

    new Flash("Appearance settings saved", "notice")

  $('.update-username form').on 'ajax:before', ->
    $('.loading-gif').show()
    $(this).find('.update-success').hide()
    $(this).find('.update-failed').hide()

  $('.update-username form').on 'ajax:complete', ->
    $(this).find('.btn-save').enableButton()
    $(this).find('.loading-gif').hide()

  $('.update-notifications').on 'ajax:complete', ->
    $(this).find('.btn-save').enableButton()
