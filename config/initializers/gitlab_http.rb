# frozen_string_literal: true

# When including this gem, we also initialize the patch / override classes in the gem.
require 'gitlab-http'

Gitlab::HTTP_V2.configure do |config|
  config.allowed_internal_uris = [
    URI::HTTP.build(
      scheme: Gitlab.config.gitlab.protocol,
      host: Gitlab.config.gitlab.host,
      port: Gitlab.config.gitlab.port
    ),
    URI::Generic.build(
      scheme: 'ssh',
      host: Gitlab.config.gitlab_shell.ssh_host,
      port: Gitlab.config.gitlab_shell.ssh_port
    )
  ]

  config.log_exception_proc = ->(exception, extra_info) do
    Gitlab::ErrorTracking.log_exception(exception, extra_info)
  end
  config.silent_mode_log_info_proc = ->(message, http_method) do
    Gitlab::SilentMode.log_info(message: message, outbound_http_request_method: http_method)
  end
end
