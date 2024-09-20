# frozen_string_literal: true

if Gem::Version.new(ActiveRecord.gem_version) >= Gem::Version.new('7.1.0')
  raise "This patch is not needed in Rails 7.1 and up"
end

ActiveRecord::ConnectionAdapters::ConnectionPool.prepend(Gitlab::Patch::ActiveRecordConnectionPool)
