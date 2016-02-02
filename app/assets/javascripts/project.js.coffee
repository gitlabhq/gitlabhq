class @Project
  constructor: ->
    # Git protocol switcher
    $('ul.clone-options-dropdown a').click ->
      return if $(@).hasClass('active')


      # Remove the active class for all buttons (ssh, http, kerberos if shown)
      $('.active').not($(@)).removeClass('active');
      # Add the active class for the clicked button
      $(@).toggleClass('active')

      url = $("#project_clone").val()
      console.log("url",url)

      # Update the input field
      $('#project_clone').val(url)

      # Update the command line instructions
      $('.clone').text(url)

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

    $('.update-notification').on 'click', (e) ->
      e.preventDefault()
      notification_level = $(@).data 'notification-level'
      $('#notification_level').val(notification_level)
      $('#notification-form').submit()
      label = null
      switch notification_level
        when 0 then label = ' Disabled '
        when 1 then label = ' Participating '
        when 2 then label = ' Watching '
        when 3 then label = ' Global '
        when 4 then label = ' On Mention '
      $('#notifications-button').empty().append("<i class='fa fa-bell'></i>" + label + "<i class='fa fa-angle-down'></i>")
      $(@).parents('ul').find('li.active').removeClass 'active'
      $(@).parent().addClass 'active'

    @projectSelectDropdown()

  projectSelectDropdown: ->
    new ProjectSelect()

    $('.project-item-select').on 'click', (e) =>
      @changeProject $(e.currentTarget).val()

    $('.js-projects-dropdown-toggle').on 'click', (e) ->
      e.preventDefault()

      $('.js-projects-dropdown').select2('open')

  changeProject: (url) ->
    window.location = url
