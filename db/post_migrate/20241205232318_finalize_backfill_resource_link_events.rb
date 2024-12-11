# frozen_string_literal: true

class FinalizeBackfillResourceLinkEvents < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # no-op
    # See details: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/174621#note_2250503192
  end

  def down; end
end
