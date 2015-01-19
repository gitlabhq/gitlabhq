class @Project
  constructor: ->
    # Git clone panel switcher
    scope = $ '.git-clone-holder'
    if scope.length > 0
      $('a, button', scope).click ->
        $('a, button', scope).removeClass 'active'
        $(@).addClass 'active'
        $('#project_clone', scope).val $(@).data 'clone'
        $(".clone").text("").append $(@).data 'clone'

    # Ref switcher
    $('.project-refs-select').on 'change', ->
      $(@).parents('form').submit()

    $('.hide-no-ssh-message').on 'click', (e) ->
      path = '/'
      $.cookie('hide_no_ssh_message', 'false', { path: path })
      $(@).parents('.no-ssh-key-message').hide()
      e.preventDefault()
