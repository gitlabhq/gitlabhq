# frozen_string_literal: true

module Gitlab
  # Provides routines to identify the current runtime as which the application
  # executes, such as whether it is an application server and which one.
  module Runtime
    IdentificationError = Class.new(RuntimeError)
    AmbiguousProcessError = Class.new(IdentificationError)
    UnknownProcessError = Class.new(IdentificationError)

    AVAILABLE_RUNTIMES = [
      :console,
      :geo_log_cursor,
      :puma,
      :rails_runner,
      :rake,
      :sidekiq,
      :test_suite
    ].freeze

    class << self
      def identify
        matches = AVAILABLE_RUNTIMES.select { |runtime| public_send("#{runtime}?") } # rubocop:disable GitlabSecurity/PublicSend

        if matches.one?
          matches.first
        elsif matches.none?
          raise UnknownProcessError, "Failed to identify runtime for process #{Process.pid} (#{$0})"
        else
          raise AmbiguousProcessError, "Ambiguous runtime #{matches} for process #{Process.pid} (#{$0})"
        end
      end

      def puma?
        !!defined?(::Puma)
      end

      def sidekiq?
        !!(defined?(::Sidekiq) && Sidekiq.server?)
      end

      def rake?
        !!(defined?(::Rake) && Rake.application.top_level_tasks.any?)
      end

      def test_suite?
        Rails.env.test?
      end

      def console?
        !!defined?(::Rails::Console)
      end

      def geo_log_cursor?
        !!defined?(::GeoLogCursorOptionParser)
      end

      def rails_runner?
        !!defined?(::Rails::Command::RunnerCommand)
      end

      def web_server?
        puma?
      end

      def action_cable?
        web_server? && (!!defined?(ACTION_CABLE_SERVER) || Gitlab::ActionCable::Config.in_app?)
      end

      def multi_threaded?
        puma? || sidekiq? || action_cable?
      end

      def puma_in_clustered_mode?
        return unless puma?
        return unless Puma.respond_to?(:cli_config)

        Puma.cli_config.options[:workers].to_i > 0
      end

      def max_threads
        threads = 1 # main thread

        if puma? && Puma.respond_to?(:cli_config)
          threads += Puma.cli_config.options[:max_threads]
        elsif sidekiq?
          # An extra thread for the poller in Sidekiq Cron:
          # https://github.com/ondrejbartas/sidekiq-cron#under-the-hood
          threads += Sidekiq.options[:concurrency] + 1
        end

        if action_cable?
          threads += Gitlab::ActionCable::Config.worker_pool_size
        end

        threads
      end
    end
  end
end
