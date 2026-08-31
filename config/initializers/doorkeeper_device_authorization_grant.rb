# frozen_string_literal: true

Doorkeeper::DeviceAuthorizationGrant.configure do
  # For future configuration
  # Minimum device code polling interval expected from the client, expressed in seconds.
  # device_code_polling_interval 5

  # Device code expiration time, in seconds.
  # device_code_expires_in 300

  # Customizable reference to the DeviceGrant model.
  # device_grant_class 'Doorkeeper::DeviceAuthorizationGrant::DeviceGrant'

  # Reference to a model (or class) for user code generation.
  #
  # It must implement a `.generate` method, which can be invoked without
  # arguments, to obtain a String user code value.
  #
  # user_code_generator 'Doorkeeper::DeviceAuthorizationGrant::OAuth::Helpers::UserCode'

  # A Proc returning the end-user verification URI on the authorization server.
  #
  # The gem's default builds this from the raw request host/scheme, which
  # does not account for `relative_url_root` (GitLab's `external_url` path
  # prefix). Use the actual route instead, which already does.
  verification_uri ->(_host_name) do
    Gitlab::Routing.url_helpers.oauth_device_authorizations_index_url
  end

  # A Proc returning the verification URI that includes the "user_code"
  # (or other information with the same function as the "user_code"), which is
  # designed for non-textual transmission. This is optional, so the Proc can
  # also return `nil`.
  verification_uri_complete ->(verification_uri, _host_name, device_grant) do
    "#{verification_uri}?user_code=#{CGI.escape(device_grant.user_code)}"
  end
end
