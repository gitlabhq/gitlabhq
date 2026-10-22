# frozen_string_literal: true

# Adapters for the ports the `gitlab-banzai` gem declares on
# `Banzai::Configuration`.
Banzai.configure do |config|
  # Driven by the `GITLAB_DISABLE_MARKDOWN_TIMEOUT` environment variable.
  config.timeout_disabled = -> { Gitlab::RenderTimeout.banzai_timeout_disabled? }
  config.with_timeout = ->(seconds, &block) do
    Gitlab::RenderTimeout.timeout(foreground: seconds, background: seconds, &block)
  end
  config.track_exception = ->(exception, **extra) { Gitlab::ErrorTracking.track_exception(exception, **extra) }
end
