class @U2FError
  constructor: (@errorCode) ->
    @httpsDisabled = (window.location.protocol isnt 'https:')
    console.error("U2F Error Code: #{@errorCode}")

  message: () =>
    switch
      when (@errorCode is u2f.ErrorCodes.BAD_REQUEST and @httpsDisabled)
        "U2F only works with HTTPS-enabled websites. Contact your administrator for more details."
      when @errorCode is u2f.ErrorCodes.DEVICE_INELIGIBLE
        "This device has already been registered with us."
      else
        "There was a problem communicating with your device."
