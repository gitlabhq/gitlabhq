# Register U2F (universal 2nd factor) devices for users to authenticate with.
#
# State Flow #1: setup -> in_progress -> registered -> POST to server
# State Flow #2: setup -> in_progress -> error -> setup

class @U2FRegister
  constructor: (@container, u2fParams) ->
    @appId = u2fParams.app_id
    @registerRequests = u2fParams.register_requests
    @signRequests = u2fParams.sign_requests

  start: () =>
    if U2FUtil.isU2FSupported()
      @renderSetup()
    else
      @renderNotSupported()

  register: () =>
    u2f.register(@appId, @registerRequests, @signRequests, (response) =>
      if response.errorCode
        error = new U2FError(response.errorCode)
        @renderError(error);
      else
        @renderRegistered(JSON.stringify(response))
    , 10)

  #############
  # Rendering #
  #############

  templates: {
    "notSupported": "#js-register-u2f-not-supported",
    "setup": '#js-register-u2f-setup',
    "inProgress": '#js-register-u2f-in-progress',
    "error": '#js-register-u2f-error',
    "registered": '#js-register-u2f-registered'
  }

  renderTemplate: (name, params) =>
    templateString = $(@templates[name]).html()
    template = _.template(templateString)
    @container.html(template(params))

  renderSetup: () =>
    @renderTemplate('setup')
    @container.find('#js-setup-u2f-device').on('click', @renderInProgress)

  renderInProgress: () =>
    @renderTemplate('inProgress')
    @register()

  renderError: (error) =>
    @renderTemplate('error', {error_message: error.message()})
    @container.find('#js-u2f-try-again').on('click', @renderSetup)

  renderRegistered: (deviceResponse) =>
    @renderTemplate('registered')
    # Prefer to do this instead of interpolating using Underscore templates
    # because of JSON escaping issues.
    @container.find("#js-device-response").val(deviceResponse)

  renderNotSupported: () =>
    @renderTemplate('notSupported')
