# frozen_string_literal: true

module Gitlab
  # Provides routines to identify the current runtime as which the application
  # executes, such as whether it is an application server and which one.
  module Runtime
    AmbiguousProcessError = Class.new(StandardError)
    UnknownProcessError = Class.new(StandardError)

    class << self
      def identify
        matches = []
        matches << :puma if puma?
        matches << :unicorn if unicorn?
        matches << :console if console?
        matches << :sidekiq if sidekiq?

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

      def console?
        !!defined?(::Rails::Console)
      end

      def web_server?
        puma? || unicorn?
      end

      def multi_threaded?
        puma? || sidekiq?
      end
    end
  end
end
