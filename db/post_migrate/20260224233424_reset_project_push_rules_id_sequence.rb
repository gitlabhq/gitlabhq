# frozen_string_literal: true

class ResetProjectPushRulesIdSequence < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    execute(<<~SQL)
      SELECT setval(
        pg_get_serial_sequence('project_push_rules', 'id'),
        GREATEST(
          (SELECT COALESCE(MAX(id), 0) FROM project_push_rules) + 100,
          nextval(pg_get_serial_sequence('project_push_rules', 'id'))
        )
      );
    SQL
  end

  def down
    # no-op
  end
end
