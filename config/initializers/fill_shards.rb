# frozen_string_literal: true

# The explicit schema version check is needed because during our migration rollback testing,
# `Shard.connected?` could be cached and return true even though the table doesn't exist
return unless Shard.connected?
return unless ActiveRecord::Migrator.current_version >= 20190402150158
return if Gitlab::Database.main.read_only?

Shard.populate!
