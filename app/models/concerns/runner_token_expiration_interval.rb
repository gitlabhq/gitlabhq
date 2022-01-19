# frozen_string_literal: true

module RunnerTokenExpirationInterval
  extend ActiveSupport::Concern

  def enforced_runner_token_expiration_interval_human_readable
    interval = enforced_runner_token_expiration_interval
    ChronicDuration.output(interval, format: :short) if interval
  end

  def effective_runner_token_expiration_interval
    [
      enforced_runner_token_expiration_interval,
      runner_token_expiration_interval&.seconds
    ].compact.min
  end

  def effective_runner_token_expiration_interval_human_readable
    interval = effective_runner_token_expiration_interval
    ChronicDuration.output(interval, format: :short) if interval
  end
end
