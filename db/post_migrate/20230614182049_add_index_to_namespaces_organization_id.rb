# frozen_string_literal: true

class AddIndexToNamespacesOrganizationId < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_namespaces_on_organization_id'
  TABLE = :namespaces

  disable_ddl_transaction!

  # This index was added on GitLab SaaS in
  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120822

  # rubocop:disable Migration/PreventIndexCreation
  def up
    add_concurrent_index TABLE, :organization_id, name: INDEX_NAME
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    remove_concurrent_index_by_name TABLE, INDEX_NAME
  end
end
