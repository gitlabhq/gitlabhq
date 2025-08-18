# frozen_string_literal: true

InvisibleCaptcha.setup do |config|
  config.honeypots = %w[firstname lastname]
  config.timestamp_enabled = true
  config.timestamp_threshold = 4
  config.spinner_enabled     = false
end
