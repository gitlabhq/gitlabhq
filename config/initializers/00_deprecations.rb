# frozen_string_literal: true

# Silence warnings:

# PG::Coder.new(hash) is deprecated. Please use keyword arguments instead! Called from ...
# https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118484#note_1366522061
# Can be removed with Rails 7.0.
Warning.ignore(/PG::Coder.new\(hash\) is deprecated/)

if Rails.env.production?
  ActiveSupport::Deprecation.silenced = !Gitlab::Utils.to_boolean(ENV['GITLAB_LOG_DEPRECATIONS'])
  ActiveSupport::Deprecation.behavior = :notify
  # Disallowed deprecation warnings are silenced in production. For performance
  # reasons we even skip the definition of `ActiveSupport::Deprecation.disallowed_warnings`
  # in production.
  # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/92557#note_1032212676 for benchmarks.
  ActiveSupport::Deprecation.disallowed_behavior = :silence
else
  ActiveSupport::Deprecation.silenced = false
  ActiveSupport::Deprecation.behavior = [:stderr, :notify]

  # rubocop:disable Lint/RaiseException
  # Raising an `Exception` instead of `DeprecationException` or `StandardError`
  # increases the probability that this exception is not caught in application
  # code.
  raise_exception = ->(message, _, _, _) { raise Exception, message }
  # rubocop:enable Lint/RaiseException

  ActiveSupport::Deprecation.disallowed_behavior = [:stderr, raise_exception]

  rails7_deprecation_warnings = [
    # https://gitlab.com/gitlab-org/gitlab/-/issues/366910
    /no longer takes non-deterministic result/,
    # https://gitlab.com/gitlab-org/gitlab/-/issues/339739
    /ActiveModel::Errors/,
    # https://gitlab.com/gitlab-org/gitlab/-/issues/342492
    /Rendering actions with '\.' in the name is deprecated/,
    # https://gitlab.com/gitlab-org/gitlab/-/issues/333086
    /default_hash is deprecated/,
    # https://gitlab.com/gitlab-org/gitlab/-/issues/369970
    /Passing an Active Record object to `\w+` directly is deprecated/,
    # https://gitlab.com/gitlab-org/gitlab/-/issues/410086
    /Using `return`, `break` or `throw` to exit a transaction block/,
    # https://gitlab.com/gitlab-org/gitlab/-/issues/414556
    /Merging .* no longer maintain both conditions, and will be replaced by the latter in Rails 7\.0/,
    # https://gitlab.com/gitlab-org/gitlab/-/issues/415890
    /(Date|Time|TimeWithZone)#to_s.+ is deprecated/,
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129686
    /Sum of non-numeric elements requires an initial argument/
  ]

  view_component_3_warnings = [
    # https://gitlab.com/gitlab-org/gitlab/-/issues/408988
    /Setting a slot with `#\w+` is deprecated and will be removed from ViewComponent 3.0.0/
  ]
  ActiveSupport::Deprecation.disallowed_warnings = rails7_deprecation_warnings + view_component_3_warnings
end

unless ActiveSupport::Deprecation.silenced
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
    Gitlab::DeprecationJsonLogger.info(message: payload[:message].strip, source: 'rails')
  end
end
