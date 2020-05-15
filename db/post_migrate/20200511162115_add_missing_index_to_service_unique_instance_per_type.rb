# frozen_string_literal: true

class AddMissingIndexToServiceUniqueInstancePerType < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # This is a corrective migration to keep the index on instance column.
  # Upgrade from 12.7 to 12.9 removes the instance column as it was first added
  # in the normal migration and then removed in the post migration.
  #
  # 12.8 removed the instance column in a post deployment migration https://gitlab.com/gitlab-org/gitlab/-/merge_requests/24885
  # 12.9 added the instance column in a normal migration https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25714
  def up
    unless index_exists_by_name?(:services, 'index_services_on_type_and_instance')
      add_concurrent_index(:services, [:type, :instance], unique: true, where: 'instance IS TRUE')
    end
  end

  def down
    # Does not apply
  end
end
