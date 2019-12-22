# frozen_string_literal: true

begin
  current_runtime = Gitlab::Runtime.identify
  Gitlab::AppLogger.info("Process #{Process.pid} (#{$0}) identified as: #{current_runtime}")
rescue => e
  message = <<-NOTICE
  \n!! RUNTIME IDENTIFICATION FAILED: #{e}
  Runtime based configuration settings may not work properly.
  If you continue to see this error, please file an issue via
  https://gitlab.com/gitlab-org/gitlab/issues/new
  NOTICE
  Gitlab::AppLogger.error(message)
  Gitlab::ErrorTracking.track_exception(e)
end
