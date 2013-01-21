$ ->
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
    visible_log = $(".file_content:visible")
    visible_log.animate({ scrollTop: visible_log.find('ol').height() }, "fast")
