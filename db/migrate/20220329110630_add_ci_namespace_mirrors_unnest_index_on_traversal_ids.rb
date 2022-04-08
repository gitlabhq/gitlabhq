# frozen_string_literal: true

class AddCiNamespaceMirrorsUnnestIndexOnTraversalIds < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_namespace_mirrors_on_traversal_ids_unnest'

  def up
    return if index_exists_by_name?(:ci_namespace_mirrors, INDEX_NAME)

    # We add only 4-levels since on average it is not expected that namespaces
    # will be so granular beyond this point
    disable_statement_timeout do
      execute <<-SQL
        CREATE INDEX CONCURRENTLY #{INDEX_NAME} ON ci_namespace_mirrors
          USING btree ((traversal_ids[1]), (traversal_ids[2]), (traversal_ids[3]), (traversal_ids[4]))
          INCLUDE (traversal_ids, namespace_id)
      SQL
    end
  end

  def down
    remove_concurrent_index_by_name(:ci_namespace_mirrors, INDEX_NAME)
  end
end
