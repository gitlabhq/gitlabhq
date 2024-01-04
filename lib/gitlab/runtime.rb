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
          raise UnknownProcessError, "Failed to identify runtime for process #{Process.pid} (#{$PROGRAM_NAME})"
        else
          raise AmbiguousProcessError, "Ambiguous runtime #{matches} for process #{Process.pid} (#{$PROGRAM_NAME})"
        end
      end

      def safe_identify
        identify
      rescue UnknownProcessError, AmbiguousProcessError
        nil
      end

      def puma?
        !!defined?(::Puma::Server)
      end

      def sidekiq?
        !!(defined?(::Sidekiq) && Sidekiq.try(:server?))
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

      # Whether we are executing in an actual application context i.e. Puma or Sidekiq.
      def application?
        puma? || sidekiq?
      end

      # Whether we are executing in a multi-threaded environment. For now this is equivalent
      # to meaning Puma or Sidekiq, but this could change in the future.
      def multi_threaded?
        application?
      end

      def puma_in_clustered_mode?
        return unless puma?
        return unless ::Puma.respond_to?(:cli_config)

        ::Puma.cli_config.options[:workers].to_i > 0
      end

      def max_threads
        threads = 1 # main thread

        if puma? && ::Puma.respond_to?(:cli_config)
          threads += ::Puma.cli_config.options[:max_threads]
        elsif sidekiq?
          # Sidekiq has a internal connection pool to handle heartbeat, scheduled polls,
          # cron polls and housekeeping. max_threads can match Sidekqi process's concurrency.
          #
          # The Sidekiq main thread does not perform GitLab-related logic, so we can ignore it.
          threads = Sidekiq.default_configuration[:concurrency]
        end

        if puma?
          threads += Gitlab::ActionCable::Config.worker_pool_size
        end

        threads
      end
    end
  end
end
