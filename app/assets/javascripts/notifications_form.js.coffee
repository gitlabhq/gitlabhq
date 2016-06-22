class @NotificationsForm
  constructor: ->
    @removeEventListeners()
    @initEventListeners()

  removeEventListeners: ->
    $(document).off 'change', '.js-custom-notification-event'

  initEventListeners: ->
    $(document).on 'change', '.js-custom-notification-event', @toggleCheckbox

  toggleCheckbox: (e) =>
    $checkbox = $(e.currentTarget)
    $parent = $checkbox.closest('.checkbox')
    @saveEvent($checkbox, $parent)

  showCheckboxLoadingSpinner: ($parent) ->
    $parent
      .addClass 'is-loading'
      .find '.custom-notification-event-loading'
      .removeClass 'fa-check'
      .addClass 'fa-spin fa-spinner'
      .removeClass 'is-done'

  saveEvent: ($checkbox, $parent) ->
    form = $parent.parents('form:first')

    $.ajax(
      url: form.attr('action')
      method: form.attr('method')
      dataType: 'json'
      data: form.serialize()

      beforeSend: =>
        @showCheckboxLoadingSpinner($parent)
    ).done (data) ->
      $checkbox.enable()

      if data.saved
        $parent
          .find '.custom-notification-event-loading'
          .toggleClass 'fa-spin fa-spinner fa-check is-done'

        setTimeout(->
          $parent
            .removeClass 'is-loading'
            .find '.custom-notification-event-loading'
            .toggleClass 'fa-spin fa-spinner fa-check is-done'
        , 2000)
