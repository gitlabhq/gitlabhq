# frozen_string_literal: true

class Gitlab::Ci::Build::AutoRetry
  include Gitlab::Utils::StrongMemoize

  DEFAULT_RETRIES = {
    scheduler_failure: 2
  }.freeze

  RETRY_OVERRIDES = {
    ci_quota_exceeded: 0,
    no_matching_runner: 0,
    missing_dependency_failure: 0,
    forward_deployment_failure: 0,
    environment_creation_failure: 0
  }.freeze

  def initialize(build)
    @build = build
  end

  def allowed?
    return false unless @build.retryable?

    within_max_retry_limit?
  end

  private

  delegate :failure_reason, to: :@build

  def within_max_retry_limit?
    max_allowed_retries > 0 && max_allowed_retries > @build.retries_count
  end

  def max_allowed_retries
    strong_memoize(:max_allowed_retries) do
      RETRY_OVERRIDES[failure_reason.to_sym] ||
        options_retry_max ||
        DEFAULT_RETRIES[failure_reason.to_sym] ||
        0
    end
  end

  def options_retry_max
    Integer(options_retry[:max], exception: false) if retry_on_reason_or_always? || retry_on_exit_code?
  end

  def options_retry_when
    default = options_retry_exit_codes.nil? ? ['always'] : []

    options_retry.fetch(:when, default) || default
  end

  def options_retry_exit_codes
    options_retry.fetch(:exit_codes, nil)
  end

  def retry_on_reason_or_always?
    options_retry_when.include?(failure_reason.to_s) ||
      options_retry_when.include?('always')
  end

  def retry_on_exit_code?
    return false unless @build.exit_code

    options_retry_exit_codes&.include?(@build.exit_code)
  end

  # The format of the retry option changed in GitLab 11.5: Before it was
  # integer only, after it is a hash. New builds are created with the new
  # format, but builds created before GitLab 11.5 and saved in database still
  # have the old integer only format. This method returns the retry option
  # normalized as a hash in 11.5+ format.
  def options_retry
    strong_memoize(:options_retry) do
      value = @build.options&.dig(:retry)
      value = value.is_a?(Integer) ? { max: value } : value.to_h
      value.with_indifferent_access
    end
  end
end
