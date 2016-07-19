# Authenticate U2F (universal 2nd factor) devices for users to authenticate with.
#
# State Flow #1: setup -> in_progress -> authenticated -> POST to server
# State Flow #2: setup -> in_progress -> error -> setup

class @U2FAuthenticate
  constructor: (@container, u2fParams) ->
    @appId = u2fParams.app_id
    @challenge = u2fParams.challenge

    # The U2F Javascript API v1.1 requires a single challenge, with
    # _no challenges per-request_. The U2F Javascript API v1.0 requires a
    # challenge per-request, which is done by copying the single challenge
    # into every request.
    #
    # In either case, we don't need the per-request challenges that the server
    # has generated, so we can remove them.
    #
    # Note: The server library fixes this behaviour in (unreleased) version 1.0.0.
    # This can be removed once we upgrade.
    # https://github.com/castle/ruby-u2f/commit/103f428071a81cd3d5f80c2e77d522d5029946a4
    @signRequests = u2fParams.sign_requests.map (request) -> _(request).omit('challenge')

  start: () =>
    if U2FUtil.isU2FSupported()
      @renderSetup()
    else
      @renderNotSupported()

  authenticate: () =>
    u2f.sign(@appId, @challenge, @signRequests, (response) =>
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
