class @UsernameValidator
  DEBOUNCE_TIMEOUT_DURATION = 1000
  ERROR_ICON_CLASSES = 'fa fa-exclamation-circle error'
  USERNAME_IN_USE_MESSAGE = 'Username "$1" is in use!'
  LOADING_ICON_CLASSES = 'fa fa-spinner fa-spin'
  SUCCESS_ICON_CLASSES = 'fa fa-check-circle success'
  TOOLTIP_PLACEMENT = 'left'

  constructor: () ->
    @inputElement = $('#new_user_username')
    @iconElement  = $('<i></i>')
    @inputElement.parent().append @iconElement

    debounceTimeout = _.debounce @validateUsername, DEBOUNCE_TIMEOUT_DURATION

    @inputElement.keyup =>
      @iconElement.removeClass().tooltip 'destroy'
      username = @inputElement.val()
      return if username is ''
      @iconElement.addClass LOADING_ICON_CLASSES
      debounceTimeout username

  validateUsername: (username) =>
    $.ajax
      type: 'GET'
      url: "/u/#{username}/exists"
      dataType: 'json'
      success: (res) =>
        if res.exists
          @iconElement.removeClass().addClass ERROR_ICON_CLASSES
            .tooltip
              title: USERNAME_IN_USE_MESSAGE.replace /\$1/g, username
              placement: TOOLTIP_PLACEMENT
        else
          @iconElement.removeClass().addClass SUCCESS_ICON_CLASSES
            .tooltip 'destroy'
