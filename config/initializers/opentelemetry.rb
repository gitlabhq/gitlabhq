# frozen_string_literal: true

# NOTE: We are using an ENV var 'GITLAB_ENABLE_OTEL_EXPORTERS' to enable instead of a feature flag or Settings module,
#       because these may not yet be fully configured or usable by this point in the Rails initialization process.
if Gitlab::Utils.to_boolean(ENV['GITLAB_ENABLE_OTEL_EXPORTERS'], default: false) &&
    (::Gitlab.dev_or_test_env? || ::Gitlab.staging?)
  Bundler.require(:opentelemetry)
  OpenTelemetry::SDK.configure(&:use_all)
end
