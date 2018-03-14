Rails.application.config.peek.adapter = :redis, { client: ::Redis.new(Gitlab::Redis::Cache.params) }

Peek.into Peek::Views::Host
Peek.into Peek::Views::PerformanceBar

if Gitlab::Database.mysql?
  require 'peek-mysql2'
  PEEK_DB_CLIENT = ::Mysql2::Client
  PEEK_DB_VIEW = Peek::Views::Mysql2
elsif Gitlab::Database.postgresql?
  require 'peek-pg'
  PEEK_DB_CLIENT = ::PG::Connection
  PEEK_DB_VIEW = Peek::Views::PG
else
  raise "Unsupported database adapter for peek!"
end

Peek.into PEEK_DB_VIEW
Peek.into Peek::Views::Gitaly
Peek.into Peek::Views::Rblineprof
Peek.into Peek::Views::Redis
Peek.into Peek::Views::Sidekiq
Peek.into Peek::Views::GC

# rubocop:disable Naming/ClassAndModuleCamelCase
class PEEK_DB_CLIENT
  class << self
    attr_accessor :query_details
  end
  self.query_details = Concurrent::Array.new
end

PEEK_DB_VIEW.prepend ::Gitlab::PerformanceBar::PeekQueryTracker
