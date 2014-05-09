class Admin
  constructor: ->
    $('input#user_force_random_password').on 'change', (elem) ->
      elems = $('#user_password, #user_password_confirmation')

      if $(@).attr 'checked'
        elems.val('').attr 'disabled', true
      else
        elems.removeAttr 'disabled'

    $('body').on 'click', '.js-toggle-colors-link', (e) ->
      e.preventDefault()
      $('.js-toggle-colors-link').hide()
      $('.js-toggle-colors-container').show()

    $('input#broadcast_message_color').on 'input', ->
      previewColor = $('input#broadcast_message_color').val()
      $('div.broadcast-message-preview').css('background-color', previewColor)

    $('input#broadcast_message_font').on 'input', ->
      previewColor = $('input#broadcast_message_font').val()
      $('div.broadcast-message-preview').css('color', previewColor)

    $('textarea#broadcast_message_message').on 'input', ->
      previewMessage = $('textarea#broadcast_message_message').val()
      $('div.broadcast-message-preview span').text(previewMessage)

    $('.log-tabs a').click (e) ->
      e.preventDefault()
      $(this).tab('show')

    $('.log-bottom').click (e) ->
      e.preventDefault()
      visible_log = $(".file-content:visible")
      visible_log.animate({ scrollTop: visible_log.find('ol').height() }, "fast")

    modal = $('.change-owner-holder')

    $('.change-owner-link').bind "click", (e) ->
      e.preventDefault()
      $(this).hide()
      modal.show()

    $('.change-owner-cancel-link').bind "click", (e) ->
      e.preventDefault()
      modal.hide()
      $('.change-owner-link').show()

    $('li.users_project').bind 'ajax:success', ->
      Turbolinks.visit(location.href)

    $('li.users_group').bind 'ajax:success', ->
      Turbolinks.visit(location.href)

@Admin = Admin
