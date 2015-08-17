class @Project
  constructor: ->
    # Git clone panel switcher
    cloneHolder = $('.git-clone-holder')
    if cloneHolder.length
      $('a, button', cloneHolder).click ->
        $('a, button', cloneHolder).removeClass 'active'
        $(@).addClass 'active'
        $('#project_clone', cloneHolder).val $(@).data 'clone'
        $(".clone").text("").append $(@).data 'clone'

    # Ref switcher
    $('.project-refs-select').on 'change', ->
      $(@).parents('form').submit()

    $('.hide-no-ssh-message').on 'click', (e) ->
      path = '/'
      $.cookie('hide_no_ssh_message', 'false', { path: path })
      $(@).parents('.no-ssh-key-message').remove()
      e.preventDefault()

    $('.hide-no-password-message').on 'click', (e) ->
      path = '/'
      $.cookie('hide_no_password_message', 'false', { path: path })
      $(@).parents('.no-password-message').remove()
      e.preventDefault()
