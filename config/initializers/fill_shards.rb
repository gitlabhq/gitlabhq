return if Gitlab::Database.read_only?

Shard.populate!
