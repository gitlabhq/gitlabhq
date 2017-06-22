class RemoveDuplicatedVariable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    if Gitlab::Database.postgresql?
      execute <<~SQL
        DELETE FROM ci_variables var USING (#{duplicated_ids}) dup
          #{join_conditions}
      SQL
    else
      execute <<~SQL
        DELETE var FROM ci_variables var INNER JOIN (#{duplicated_ids}) dup
          #{join_conditions}
      SQL
    end
  end

  def down
    # noop
  end

  def duplicated_ids
    <<~SQL
      SELECT MAX(id) AS id, #{key}, project_id
        FROM ci_variables GROUP BY #{key}, project_id
    SQL
  end

  def join_conditions
    <<~SQL
      WHERE var.key = dup.key
        AND var.project_id = dup.project_id
        AND var.id <> dup.id
    SQL
  end

  def key
    # key needs to be quoted in MySQL
    quote_column_name('key')
  end
end
