# frozen_string_literal: true

module Gitlab
  # Provides routines to identify the current runtime as which the application
  # executes, such as whether it is an application server and which one.
  module Runtime
    IdentificationError = Class.new(RuntimeError)
    AmbiguousProcessError = Class.new(IdentificationError)
    UnknownProcessError = Class.new(IdentificationError)

    class << self
      def identify
        matches = []
        matches << :puma if puma?
        matches << :unicorn if unicorn?
        matches << :console if console?
        matches << :sidekiq if sidekiq?
        matches << :rake if rake?
        matches << :rspec if rspec?

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

      def rspec?
        Rails.env.test? && process_name == 'rspec'
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

      def process_name
        File.basename($0)
      end
    end
  end
end
