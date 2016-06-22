class @NotificationsDropdown
  constructor: ->
    $(document)
      .off 'click', '.update-notification'
      .on 'click', '.update-notification', (e) ->
        e.preventDefault()

        return if $(this).is('.is-active') and $(this).data('notification-level') is 'custom'

        notificationLevel = $(@).data 'notification-level'
        label = $(@).data 'notification-title'
        form = $(this).parents('.notification-form:first')
        form.find('.js-notification-loading').toggleClass 'fa-bell fa-spin fa-spinner'
        form.find('#notification_setting_level').val(notificationLevel)
        form.submit()

    $(document)
      .off 'ajax:success', '.notification-form'
      .on 'ajax:success', '.notification-form', (e, data) ->
        if data.saved
          $(e.currentTarget)
            .closest('.notification-dropdown')
            .replaceWith(data.html)
        else
          new Flash('Failed to save new settings', 'alert')
