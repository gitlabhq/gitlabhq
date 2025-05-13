# frozen_string_literal: true

class AddTmpIndexRedirectRoutesOnSourceTypeIdWhereNamespaceNull < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  INDEX_NAME = 'tmp_idx_redirect_routes_on_source_type_id_where_namespace_null'

  def up
    # Temporary index to be removed in https://gitlab.com/gitlab-org/gitlab/-/issues/533959
    add_concurrent_index(
      :redirect_routes,
      [:source_type, :id],
      where: 'namespace_id IS NULL',
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name :redirect_routes, INDEX_NAME
  end
end
