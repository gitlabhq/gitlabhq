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


  $('.js-choose-user-avatar-button').bind "click", ->
    form = $(this).closest("form")
    form.find(".js-user-avatar-input").click()

  $('.js-user-avatar-input').bind "change", ->
    form = $(this).closest("form")
    filename = $(this).val().replace(/^.*[\\\/]/, '')
    form.find(".js-avatar-filename").text(filename)

  $('.profile-groups-avatars').tooltip("placement": "top")
