# frozen_string_literal: true

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
      lib/gitlab/request_profiler/
      lib/gitlab/sidekiq_logging/
      lib/gitlab/sidekiq_middleware/
      lib/gitlab/sidekiq_status/
      lib/gitlab/tracing/
      lib/gitlab/webpack/dev_server_middleware.rb
    ].freeze

    IGNORED_BACKTRACES_REGEXP = Regexp.union(IGNORE_BACKTRACES).freeze

    def self.clean_backtrace(backtrace)
      return unless backtrace

      Array(Rails.backtrace_cleaner.clean(backtrace)).reject do |line|
        line.match(IGNORED_BACKTRACES_REGEXP)
      end
    end
  end
end
