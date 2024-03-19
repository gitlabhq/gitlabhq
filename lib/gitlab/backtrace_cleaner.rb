# frozen_string_literal: true

# Remove some GitLab code from backtraces. Do not use this for logging errors in
# production environments, as the error may be thrown by our middleware.
module Gitlab
  module BacktraceCleaner
    IGNORE_BACKTRACES = %w[
      config/initializers
      ee/lib/gitlab/middleware/
      lib/gitlab/correlation_id.rb
      lib/gitlab/database/load_balancing/
      lib/gitlab/etag_caching/
      lib/gitlab/i18n.rb
      lib/gitlab/metrics/
      lib/gitlab/middleware/
      lib/gitlab/performance_bar/
      lib/gitlab/profiler.rb
      lib/gitlab/query_limiting/
      lib/gitlab/request_context.rb
      lib/gitlab/sidekiq_logging/
      lib/gitlab/sidekiq_middleware/
      lib/gitlab/sidekiq_status/
      lib/gitlab/tracing/
      lib/gitlab/webpack/dev_server_middleware.rb
    ].freeze

    IGNORED_BACKTRACES_REGEXP = Regexp.union(IGNORE_BACKTRACES).freeze

    def self.clean_backtrace(backtrace)
      return unless backtrace

      Array(backtrace_cleaner.clean(backtrace)).reject do |line|
        IGNORED_BACKTRACES_REGEXP.match?(line)
      end
    end

    def self.backtrace_cleaner
      @backtrace_cleaner ||= Rails.backtrace_cleaner.dup.tap do |cleaner|
        cleaner.add_silencer { |line| !Gitlab::APP_DIRS_PATTERN.match?(line) }
      end
    end
  end
end
