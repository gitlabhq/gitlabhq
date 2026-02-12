# frozen_string_literal: true

class ResetGroupPushRulesIdSequence < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute(<<~SQL)
      SELECT setval(
        pg_get_serial_sequence('group_push_rules', 'id'),
        GREATEST(
          (SELECT COALESCE(MAX(id), 0) FROM group_push_rules) + 1000,
          nextval(pg_get_serial_sequence('group_push_rules', 'id'))
        )
      );
    SQL
  end

  def down
    # no-op
  end
end
