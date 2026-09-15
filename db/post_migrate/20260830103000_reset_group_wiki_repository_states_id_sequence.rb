# frozen_string_literal: true

class ResetGroupWikiRepositoryStatesIdSequence < Gitlab::Database::Migration[2.3]
  milestone '19.4'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    return if Gitlab.com_except_jh?

    execute(<<~SQL)
      SELECT setval(
        pg_get_serial_sequence('group_wiki_repository_states', 'id'),
        GREATEST(
          (SELECT COALESCE(MAX(id), 0) FROM group_wiki_repository_states) + 1000,
          nextval(pg_get_serial_sequence('group_wiki_repository_states', 'id'))
        )
      );
    SQL
  end

  def down
    # no-op
  end
end
