# Based on code from:
# http://underthehood.meltwater.com/blog/2014/03/21/debugging-unicorn-rails-timeouts
require 'unicorn'

module Gitlab
  module Middleware
    class UnicornTimeoutLogger
      def initialize(app)
        @app = app
        @timeout = load_timeout
      end

      def call(env)
        if @timeout
          log_timeout(env)
        else
          @app.call(env)
        end
      end

      def log_timeout(env)
        thr = Thread.new do
          sleep(@timeout - 1)

          unless Thread.current[:done]
            path = env["PATH_INFO"]
            query_string = ENV["QUERY_STRING"]
            path += "?#{query_string}" if query_string.present?

            Rails.logger.warn "[TIMEOUT] Unicorn worker timeout: path => #{path}"
          end
        end

        @app.call(env)
      ensure
        thr[:done] = true
        thr.run if thr.alive?
      end

      private

      def load_timeout
        unicorn_config = File.join(Rails.root, 'config/unicorn.rb')

        return unless File.exist?(unicorn_config)

        configurator = Unicorn::Configurator.new({ config_file: unicorn_config })
        configurator.set[:timeout]
      end
    end
  end
end
