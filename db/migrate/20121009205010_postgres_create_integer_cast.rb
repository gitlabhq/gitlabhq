class PostgresCreateIntegerCast < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE CAST (integer AS text) WITH INOUT AS IMPLICIT;
    SQL
    rescue ActiveRecord::StatementInvalid
  end

  def down
    execute <<-SQL
      DROP CAST (integer AS text);
    SQL
    rescue ActiveRecord::StatementInvalid
  end
end
