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
      label = $(@).data 'notification-title'
      $('#notification_setting_level').val(notification_level)
      $('#notification-form').submit()
      $('#notifications-button').empty().append("<i class='fa fa-bell'></i>" + label + "<i class='fa fa-angle-down'></i>")
      $(@).parents('ul').find('li.active').removeClass 'active'
      $(@).parent().addClass 'active'

    $('#notification-form').on 'ajax:success', (e, data) ->
      if data.saved
        new Flash("Notification settings saved", "notice")
      else
        new Flash("Failed to save new settings", "alert")


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
