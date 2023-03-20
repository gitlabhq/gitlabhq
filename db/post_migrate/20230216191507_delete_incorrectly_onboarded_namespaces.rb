# frozen_string_literal: true

class DeleteIncorrectlyOnboardedNamespaces < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # Changed to a no-op, this migration was reverted after
    # an incident during a deploy to production on gitlab.com
    # https://gitlab.com/gitlab-com/gl-infra/production/-/issues/8436
  end

  def down
    # no-op
  end
end
