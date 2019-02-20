# The `table_exists?` check is needed because during our migration rollback testing,
# `Shard.connected?` could be cached and return true even though the table doesn't exist
if Shard.connected? && Shard.table_exists? && !Gitlab::Database.read_only?
  Shard.populate!
end
