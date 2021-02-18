# frozen_string_literal: true

class AddDevopsAdoptionSegmentNamespaceFk < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :analytics_devops_adoption_segments, :namespaces, column: :namespace_id
  end

  def down
    remove_foreign_key_if_exists :analytics_devops_adoption_segments, :namespaces, column: :namespace_id
  end
end
