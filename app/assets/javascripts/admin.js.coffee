$ ->
  $('input#user_force_random_password').on 'change', (elem) ->
    elems = $('#user_password, #user_password_confirmation')

    if $(@).attr 'checked'
      elems.val('').attr 'disabled', true
    else
      elems.removeAttr 'disabled'
