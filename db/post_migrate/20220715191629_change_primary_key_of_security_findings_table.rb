# frozen_string_literal: true

class ChangePrimaryKeyOfSecurityFindingsTable < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    execute(<<~SQL)
      ALTER TABLE security_findings DROP CONSTRAINT security_findings_pkey;
    SQL

    execute(<<~SQL)
      ALTER TABLE security_findings ADD CONSTRAINT security_findings_pkey PRIMARY KEY USING index security_findings_partitioned_pkey;
    SQL
  end

  def down
    execute(<<~SQL)
      ALTER TABLE security_findings DROP CONSTRAINT security_findings_pkey;
    SQL

    execute(<<~SQL)
      ALTER TABLE security_findings ADD CONSTRAINT security_findings_pkey PRIMARY KEY (id);
    SQL

    execute(<<~SQL)
      CREATE UNIQUE INDEX security_findings_partitioned_pkey ON security_findings USING btree(id, partition_number);
    SQL
  end
end
