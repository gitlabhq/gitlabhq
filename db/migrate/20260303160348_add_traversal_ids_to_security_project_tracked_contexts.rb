# frozen_string_literal: true

class AddTraversalIdsToSecurityProjectTrackedContexts < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def change
    add_column :security_project_tracked_contexts, :traversal_ids, 'bigint[]', default: [], null: false
  end
end
