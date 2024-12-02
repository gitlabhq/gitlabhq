# frozen_string_literal: true

class PrepareIidNamespaceUniqueIndexInIssues < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_issues_on_namespace_id_iid_unique'

  milestone '16.8'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/435856
  def up
    prepare_async_index :issues, [:namespace_id, :iid], unique: true, name: INDEX_NAME
  end

  def down
    unprepare_async_index :issues, [:namespace_id, :iid], unique: true, name: INDEX_NAME
  end
end
