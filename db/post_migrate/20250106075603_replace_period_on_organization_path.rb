# frozen_string_literal: true

class ReplacePeriodOnOrganizationPath < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    execute <<-SQL
        UPDATE organizations
        SET path = REPLACE(path, '.', 'dot') || '-' || SUBSTRING(gen_random_uuid()::text, 1, 8)
        WHERE path LIKE '%.%';
    SQL
  end

  def down
    # no-op
  end
end
