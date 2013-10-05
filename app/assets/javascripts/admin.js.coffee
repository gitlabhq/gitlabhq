class Admin
  constructor: ->
    $('input#user_force_random_password').on 'change', (elem) ->
      elems = $('#user_password, #user_password_confirmation')

      if $(@).attr 'checked'
        elems.val('').attr 'disabled', true
      else
        elems.removeAttr 'disabled'

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
