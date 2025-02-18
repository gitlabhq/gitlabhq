# frozen_string_literal: true

# Silence warnings:

# PG::Coder.new(hash) is deprecated. Please use keyword arguments instead! Called from ...
# https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118484#note_1366522061
# Can be removed with Rails 7.0.
Warning.ignore(/PG::Coder.new\(hash\) is deprecated/)

deprecators =
  if ::Gitlab.next_rails?
    Rails.application.deprecators
  else
    ActiveSupport::Deprecation
  end

silenced = Rails.env.production? && !Gitlab::Utils.to_boolean(ENV['GITLAB_LOG_DEPRECATIONS'])
deprecators.silenced = silenced

ignored_warnings = [
  /Your `secret_key_base` is configured in `Rails.application.secrets`, which is deprecated in favor of/,
  /Please pass the (coder|class) as a keyword argument/,
  /Support for `config.active_support.cache_format_version/
]

if Rails.env.production?
  deprecators.behavior = :notify
  # Disallowed deprecation warnings are silenced in production. For performance
  # reasons we even skip the definition of `ActiveSupport::Deprecation.disallowed_warnings`
  # in production.
  # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/92557#note_1032212676 for benchmarks.
  deprecators.disallowed_behavior = :silence
else
  # rubocop:disable Lint/RaiseException
  # Raising an `Exception` instead of `DeprecationException` or `StandardError`
  # increases the probability that this exception is not caught in application
  # code.
  raise_exception = ->(message, _, _, _) { raise Exception, message }
  # rubocop:enable Lint/RaiseException

  deprecators.disallowed_behavior = [:stderr, raise_exception]

  rails7_deprecation_warnings = []
  view_component_3_warnings = []
  deprecators.disallowed_warnings = rails7_deprecation_warnings + view_component_3_warnings

  if ::Gitlab.next_rails?
    deprecators.behavior = ->(message, callstack, deprecator) do
      if ignored_warnings.none? { |warning| warning.match?(message) }
        ActiveSupport::Deprecation::DEFAULT_BEHAVIORS.slice(:stderr, :notify).each_value do |behavior|
          behavior.call(message, callstack, deprecator)
        end
      end
    end
  else
    deprecators.behavior = [:stderr, :notify]
  end
end

unless silenced
  # Log deprecation warnings emitted through Kernel#warn, such as from gems or
  # the Ruby VM.
  actions = {
    /is deprecated/ => ->(warning) do
      Gitlab::DeprecationJsonLogger.info(message: warning.strip, source: 'ruby')
      # Returning :default means we continue emitting this to stderr as well.
      :default
    end
  }

  # Use `warning` gem to intercept Ruby warnings and add our own action hook.
  Warning.process('', actions)

  # Log deprecation warnings emitted from Rails (see ActiveSupport::Deprecation).
  ActiveSupport::Notifications.subscribe('deprecation.rails') do |_name, _start, _finish, _id, payload|
    if !::Gitlab.next_rails? || ignored_warnings.none? { |warning| warning.match?(payload[:message]) }
      Gitlab::DeprecationJsonLogger.info(message: payload[:message].strip, source: 'rails')
    end
  end
end
