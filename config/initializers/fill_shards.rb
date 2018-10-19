return unless Shard.connected?
return if Gitlab::Database.read_only?

Shard.populate!
