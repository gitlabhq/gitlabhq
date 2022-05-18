# frozen_string_literal: true

class AddTextLimitToBatchedBackgroundMigrationsGitlabSchema < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_text_limit :batched_background_migrations, :gitlab_schema, 255
  end

  def down
    remove_text_limit :batched_background_migrations, :gitlab_schema
  end
end
