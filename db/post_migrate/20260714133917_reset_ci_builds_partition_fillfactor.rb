# frozen_string_literal: true

class ResetCiBuildsPartitionFillfactor < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  DYNAMIC_SCHEMA = Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA
  TABLE_IDENTIFIER = "#{DYNAMIC_SCHEMA}.ci_builds".freeze

  def up
    return unless Gitlab.com_except_jh?
    return unless table_exists?(TABLE_IDENTIFIER)

    execute("ALTER TABLE #{TABLE_IDENTIFIER} RESET (fillfactor)")
  end

  def down
    return unless Gitlab.com_except_jh?
    return unless table_exists?(TABLE_IDENTIFIER)

    execute("ALTER TABLE #{TABLE_IDENTIFIER} SET (fillfactor=80)")
  end
end
