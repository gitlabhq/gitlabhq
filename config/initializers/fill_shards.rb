# The `table_exists?` check is needed because during our migration rollback testing,
# `Shard.connected?` could be cached and return true even though the table doesn't exist
return unless Shard.connected?
return unless Shard.table_exists?
return unless Shard.connection.index_exists?(:shards, :name, unique: true)
return if Gitlab::Database.read_only?

Shard.populate!
