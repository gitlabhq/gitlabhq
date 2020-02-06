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
      :rake,
      :sidekiq,
      :test_suite,
      :unicorn
    ].freeze

    class << self
      def identify
        matches = AVAILABLE_RUNTIMES.select { |runtime| public_send("#{runtime}?") } # rubocop:disable GitlabSecurity/PublicSend

        if matches.one?
          matches.first
        elsif matches.none?
          raise UnknownProcessError.new(
            "Failed to identify runtime for process #{Process.pid} (#{$0})"
          )
        else
          raise AmbiguousProcessError.new(
            "Ambiguous runtime #{matches} for process #{Process.pid} (#{$0})"
          )
        end
      end

      def puma?
        !!defined?(::Puma)
      end

      # For unicorn, we need to check for actual server instances to avoid false positives.
      def unicorn?
        !!(defined?(::Unicorn) && defined?(::Unicorn::HttpServer))
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

      def web_server?
        puma? || unicorn?
      end

      def multi_threaded?
        puma? || sidekiq?
      end

      def max_threads
        if puma?
          Puma.cli_config.options[:max_threads]
        elsif sidekiq?
          Sidekiq.options[:concurrency]
        else
          1
        end
      end
    end
  end
end
