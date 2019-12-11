# frozen_string_literal: true

begin
  Gitlab::AppLogger.info("Runtime: #{Gitlab::Runtime.name}")
rescue => e
  message = <<-NOTICE
  \n!! RUNTIME IDENTIFICATION FAILED: #{e}
  Runtime based configuration settings may not work properly.
  If you continue to see this error, please file an issue via
  https://gitlab.com/gitlab-org/gitlab/issues/new
  NOTICE
  Gitlab::AppLogger.error(message)
end
