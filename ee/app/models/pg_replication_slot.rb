# `pg_replication_slots` is a PostgreSQL view
class PgReplicationSlot
  def self.count
    ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM pg_replication_slots;")
    .first.fetch('count').to_i
  end

  def self.unused_slots_count
    ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM pg_replication_slots WHERE active = 'f';")
    .first.fetch('count').to_i
  end

  def self.used_slots_count
    ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM pg_replication_slots WHERE active = 't';")
    .first.fetch('count').to_i
  end

  # array of slots and the retained_bytes
  # https://www.skillslogic.com/blog/databases/checking-postgres-replication-lag
  # http://bdr-project.org/docs/stable/monitoring-peers.html
  def self.slots_retained_bytes
    ActiveRecord::Base.connection.execute(<<-SQL.squish)
      SELECT slot_name, database,
             active, #{Gitlab::Database.pg_wal_lsn_diff}(#{Gitlab::Database.pg_current_wal_insert_lsn}(), restart_lsn)
        AS retained_bytes
        FROM pg_replication_slots;
    SQL
    .to_a
  end

  # returns the max number WAL space (in bytes) being used across the replication slots
  def self.max_retained_wal
    ActiveRecord::Base.connection.execute(<<-SQL.squish)
      SELECT COALESCE(MAX(#{Gitlab::Database.pg_wal_lsn_diff}(#{Gitlab::Database.pg_current_wal_insert_lsn}(), restart_lsn)), 0)
        FROM pg_replication_slots;
    SQL
    .first.fetch('coalesce').to_i
  end

  def self.max_replication_slots
    ActiveRecord::Base.connection.execute(<<-SQL.squish)
      SELECT setting FROM pg_settings WHERE name = 'max_replication_slots';
    SQL
    .first&.fetch('setting').to_i
  end
end
