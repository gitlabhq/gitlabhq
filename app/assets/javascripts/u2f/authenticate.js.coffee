# Authenticate U2F (universal 2nd factor) devices for users to authenticate with.
#
# State Flow #1: setup -> in_progress -> authenticated -> POST to server
# State Flow #2: setup -> in_progress -> error -> setup

class @U2FAuthenticate
  constructor: (@container, u2fParams) ->
    @appId = u2fParams.app_id
    @challenges = u2fParams.challenges
    @signRequests = u2fParams.sign_requests

  start: () =>
    if U2FUtil.isU2FSupported()
      @renderSetup()
    else
      @renderNotSupported()

  authenticate: () =>
    u2f.sign(@appId, @challenges, @signRequests, (response) =>
      if response.errorCode
        error = new U2FError(response.errorCode)
        @renderError(error);
      else
        @renderAuthenticated(JSON.stringify(response))
    , 10)

  #############
  # Rendering #
  #############

  templates: {
    "notSupported": "#js-authenticate-u2f-not-supported",
    "setup": '#js-authenticate-u2f-setup',
    "inProgress": '#js-authenticate-u2f-in-progress',
    "error": '#js-authenticate-u2f-error',
    "authenticated": '#js-authenticate-u2f-authenticated'
  }

  renderTemplate: (name, params) =>
    templateString = $(@templates[name]).html()
    template = _.template(templateString)
    @container.html(template(params))

  renderSetup: () =>
    @renderTemplate('setup')
    @container.find('#js-login-u2f-device').on('click', @renderInProgress)

  renderInProgress: () =>
    @renderTemplate('inProgress')
    @authenticate()

  renderError: (error) =>
    @renderTemplate('error', {error_message: error.message()})
    @container.find('#js-u2f-try-again').on('click', @renderSetup)

  renderAuthenticated: (deviceResponse) =>
    @renderTemplate('authenticated')
    # Prefer to do this instead of interpolating using Underscore templates
    # because of JSON escaping issues.
    @container.find("#js-device-response").val(deviceResponse)

  renderNotSupported: () =>
    @renderTemplate('notSupported')
