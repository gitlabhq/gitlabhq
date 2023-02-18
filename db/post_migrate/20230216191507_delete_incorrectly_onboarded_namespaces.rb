# frozen_string_literal: true

class DeleteIncorrectlyOnboardedNamespaces < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute(<<~SQL)
      DELETE
      FROM onboarding_progresses
      WHERE onboarding_progresses.id NOT IN
          (SELECT onboarding_progresses.id
           FROM onboarding_progresses
           INNER JOIN namespaces ON namespaces.id = onboarding_progresses.namespace_id
           INNER JOIN projects ON projects.namespace_id = namespaces.id
           WHERE projects.name IN ('Learn GitLab',
                                   'Learn GitLab - Ultimate trial'))
    SQL
  end

  def down
    # no-op
  end
end
