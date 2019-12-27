# frozen_string_literal: true

begin
  Gitlab::Runtime.identify
rescue Gitlab::Runtime::IdentificationError => e
  message = <<-NOTICE
  \n!! RUNTIME IDENTIFICATION FAILED: #{e}
  Runtime based configuration settings may not work properly.
  If you continue to see this error, please file an issue via
  https://gitlab.com/gitlab-org/gitlab/issues/new
  NOTICE
  Gitlab::AppLogger.error(message)
  Gitlab::ErrorTracking.track_exception(e)
end
