# frozen_string_literal: true

class DropNameFromCiRunnerTaggings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.5'

  def up
    remove_column :ci_runner_taggings, :name, if_exists: true
  end

  def down
    # no-op - original migration was made a no-op
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205427
  end
end
