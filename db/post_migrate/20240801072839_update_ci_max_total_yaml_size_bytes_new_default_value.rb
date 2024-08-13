# frozen_string_literal: true

class UpdateCiMaxTotalYamlSizeBytesNewDefaultValue < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.3'

  def up
    execute <<~SQL
      UPDATE application_settings
      SET ci_max_total_yaml_size_bytes = CASE
        WHEN max_yaml_size_bytes * ci_max_includes >= 2147483647 THEN 2147483647
        ELSE max_yaml_size_bytes * ci_max_includes
      END
    SQL
  end

  def down
    # no-op
  end
end
