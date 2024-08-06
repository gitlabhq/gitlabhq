# frozen_string_literal: true

class UpdateMaxTotalYamlSizeBytesValue < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.3'

  def up
    old_default = 1.megabyte
    new_default = 2.megabytes
    max_int = 2147483647

    execute <<-SQL
      UPDATE application_settings
      SET max_yaml_size_bytes = CASE
        WHEN max_yaml_size_bytes = #{old_default} THEN #{new_default}
        WHEN (max_yaml_size_bytes * 1.2)::bigint >= #{max_int} THEN #{max_int}
        ELSE (max_yaml_size_bytes * 1.2)::integer
      END
      WHERE max_yaml_size_bytes != #{new_default}
    SQL
  end

  def down
    # no-op
  end
end
