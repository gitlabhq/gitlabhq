# frozen_string_literal: true

unless Gitlab.next_rails?
  ActiveRecord::ConnectionAdapters::ConnectionPool.prepend(Gitlab::Patch::ActiveRecordConnectionPool)
end
