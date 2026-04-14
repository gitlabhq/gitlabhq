# frozen_string_literal: true

gitlab_uuid_namespace_ids = {
  development: Gitlab::UUID::DEFAULT_NAMESPACE_ID,
  test: Gitlab::UUID::DEFAULT_NAMESPACE_ID,
  staging: "a6930898-a1b2-4365-ab18-12aa474d9b26",
  production: "58dc0f06-936c-43b3-93bb-71693f1b6570"
}.freeze

Gitlab::UUID.default_namespace_id = gitlab_uuid_namespace_ids.fetch(Rails.env.to_sym)

Gitlab::Json.on_limit_exceeded = ->(exception, parse_limits) do
  payload = { message: 'Exceeded allowed limits for parsing JSON input', parse_limits: parse_limits }
  Gitlab::ExceptionLogFormatter.format!(exception, payload)
  Gitlab::AppLogger.warn(payload)
end

Gitlab::Utils::Email.email_validation_regexp = Devise.email_regexp

Gitlab::Utils::TomlParser.timeout_logger = ->(exception) do
  Gitlab::ErrorTracking.log_exception(exception)
end

Gitlab::Json.on_oversize_object = ->(string) do
  oversize_threshold = ENV['GITLAB_JSON_SIZE_THRESHOLD'].to_i

  return if oversize_threshold <= 0

  total_value_count_estimate = string.count('{[,:')

  return if total_value_count_estimate < oversize_threshold

  Gitlab::AppJsonLogger.info(
    message: 'Large JSON object',
    number_of_fields: total_value_count_estimate,
    caller: Gitlab::BacktraceCleaner.clean_backtrace(caller)
  )
end
