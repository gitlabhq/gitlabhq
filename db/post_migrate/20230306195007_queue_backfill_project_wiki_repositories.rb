# frozen_string_literal: true

class QueueBackfillProjectWikiRepositories < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # no-op
  end

  def down
    # no-op
  end
end
