# frozen_string_literal: true

class ReaddIndexProjectsOnLowerName < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  INDEX_NAME = 'index_projects_on_lower_name'

  def up
    # This index was added in GitLab 11.0 with
    # https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/18553
    # but it was gated on a `Gitlab::Database.postgresql?` check. We've seen
    # some older installations missing this index.
    add_concurrent_index :projects, 'lower((name)::text)', name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- This index should have already existed
  end

  def down; end
end
