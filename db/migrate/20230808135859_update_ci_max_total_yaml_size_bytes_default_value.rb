# frozen_string_literal: true

class UpdateCiMaxTotalYamlSizeBytesDefaultValue < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # 2147483647 is the max int value.
    execute <<~SQL
      UPDATE application_settings
      SET ci_max_total_yaml_size_bytes =
      CASE WHEN max_yaml_size_bytes * ci_max_includes >= 2147483647
      THEN 2147483647 ELSE max_yaml_size_bytes * ci_max_includes END
    SQL
  end

  def down
    # No-op
  end
end
