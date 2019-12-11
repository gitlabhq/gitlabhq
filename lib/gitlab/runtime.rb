# frozen_string_literal: true

module Gitlab
  # Provides routines to identify the current runtime as which the application
  # executes, such as whether it is an application server and which one.
  module Runtime
    class << self
      def name
        matches = []
        matches << :puma if puma?
        matches << :unicorn if unicorn?
        matches << :console if console?
        matches << :sidekiq if sidekiq?

        raise "Ambiguous process match: #{matches}" if matches.size > 1

        matches.first || :unknown
      end

      def puma?
        !!(defined?(::Puma) && bin == 'puma')
      end

      # For unicorn, we need to check for actual server instances to avoid false positives.
      def unicorn?
        !!(defined?(::Unicorn) && defined?(::Unicorn::HttpServer))
      end

      def sidekiq?
        !!(defined?(::Sidekiq) && Sidekiq.server? && bin == 'sidekiq')
      end

      def console?
        !!defined?(::Rails::Console)
      end

      def app_server?
        puma? || unicorn?
      end

      def multi_threaded?
        puma? || sidekiq?
      end

      private

      # Some example values from my system:
      #   puma: /data/cache/bundle-2.5/bin/puma
      #   unicorn: unicorn_rails master -E development -c /tmp/unicorn.rb -l 0.0.0.0:8080
      #   sidekiq: /data/cache/bundle-2.5/bin/sidekiq
      #   thin: bin/rails
      #   console: bin/rails
      def script_name
        $0
      end

      def bin
        File.basename(script_name)
      end
    end
  end
end
