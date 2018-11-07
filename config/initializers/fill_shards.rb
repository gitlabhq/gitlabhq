if Shard.connected? && !Gitlab::Database.read_only?
  Shard.populate!
end
