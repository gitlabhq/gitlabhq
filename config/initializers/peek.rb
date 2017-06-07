Rails.application.config.peek.adapter = :redis, { client: ::Redis.new(Gitlab::Redis.params) }

Peek.into Peek::Views::Host
Peek.into Peek::Views::PerformanceBar
if Gitlab::Database.mysql?
  require 'peek-mysql'
  PEEK_DB_CLIENT = ::Mysql2::Client
  PEEK_DB_VIEW = Peek::Views::Mysql2
  Peek.into PEEK_DB_VIEW
else
  require 'peek-pg'
  PEEK_DB_CLIENT = ::PG::Connection
  PEEK_DB_VIEW = Peek::Views::PG
  Peek.into PEEK_DB_VIEW
end
Peek.into Peek::Views::Redis
Peek.into Peek::Views::Sidekiq
Peek.into Peek::Views::Rblineprof
Peek.into Peek::Views::GC


class PEEK_DB_CLIENT
  class << self
    attr_accessor :query_details
  end
  self.query_details = Concurrent::Array.new
end

PEEK_DB_VIEW.prepend ::Gitlab::PerformanceBar::PeekQueryTracker
