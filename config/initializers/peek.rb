Rails.application.config.peek.adapter = :redis, { client: ::Redis.new(Gitlab::Redis::Cache.params) }

Peek.into Peek::Views::Host

if Gitlab::Database.postgresql?
  require 'peek-pg'
  PEEK_DB_CLIENT = ::PG::Connection
  PEEK_DB_VIEW = Peek::Views::PG

  # Remove once we have https://github.com/peek/peek-pg/pull/10
  module ::Peek::PGInstrumented
    def exec_params(*args)
      start = Time.now
      super(*args)
    ensure
      duration = (Time.now - start)
      PEEK_DB_CLIENT.query_time.update { |value| value + duration }
      PEEK_DB_CLIENT.query_count.update { |value| value + 1 }
    end
  end
else
  raise "Unsupported database adapter for peek!"
end

Peek.into PEEK_DB_VIEW
Peek.into Peek::Views::Gitaly
Peek.into Peek::Views::Rblineprof
Peek.into Peek::Views::RedisDetailed
Peek.into Peek::Views::Rugged
Peek.into Peek::Views::GC
Peek.into Peek::Views::Tracing if Labkit::Tracing.tracing_url_enabled?

# rubocop:disable Naming/ClassAndModuleCamelCase
class PEEK_DB_CLIENT
  class << self
    attr_accessor :query_details
  end
  self.query_details = Concurrent::Array.new
end

PEEK_DB_VIEW.prepend ::Gitlab::PerformanceBar::PeekQueryTracker

require 'peek/adapters/redis'
Peek::Adapters::Redis.prepend ::Gitlab::PerformanceBar::RedisAdapterWhenPeekEnabled
