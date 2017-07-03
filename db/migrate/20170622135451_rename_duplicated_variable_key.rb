class RenameDuplicatedVariableKey < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    execute(<<~SQL)
      UPDATE ci_variables
      SET #{key} = CONCAT(#{key}, #{underscore}, id)
      WHERE id IN (
        SELECT *
        FROM ( -- MySQL requires an extra layer
          SELECT dup.id
          FROM ci_variables dup
          INNER JOIN (SELECT max(id) AS id, #{key}, project_id
                      FROM ci_variables tmp
                      GROUP BY #{key}, project_id) var
          USING (#{key}, project_id) where dup.id <> var.id
        ) dummy
      )
    SQL
  end

  def down
    # noop
  end

  def key
    # key needs to be quoted in MySQL
    quote_column_name('key')
  end

  def underscore
    quote('_')
  end
end
