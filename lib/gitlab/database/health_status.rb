# frozen_string_literal: true

module Gitlab
  module Database
    module HealthStatus
      DEFAULT_INIDICATORS = [
        Indicators::AutovacuumActiveOnTable,
        Indicators::WriteAheadLog,
        Indicators::PatroniApdex,
        Indicators::WalRate
      ].freeze

      class << self
        def evaluate(context, indicators = DEFAULT_INIDICATORS)
          indicators.map do |indicator|
            signal = begin
              indicator.new(context).evaluate
            rescue StandardError => e
              Gitlab::ErrorTracking.track_exception(e, **context.status_checker_info)

              Signals::Unknown.new(indicator, reason: "unexpected error: #{e.message} (#{e.class})")
            end

            log_signal(signal, context) if signal.log_info?

            signal
          end
        end

        def log_signal(signal, context)
          Gitlab::Database::HealthStatus::Logger.info(**context.status_checker_info.merge(
            health_status_indicator: signal.indicator_class.to_s,
            indicator_signal: signal.short_name,
            signal_reason: signal.reason,
            message: "#{context.status_checker} signaled: #{signal}"
          ))
        end
      end
    end
  end
end
