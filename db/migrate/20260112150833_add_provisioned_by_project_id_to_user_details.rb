# frozen_string_literal: true

class AddProvisionedByProjectIdToUserDetails < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def change
    add_column :user_details, :provisioned_by_project_id, :bigint
  end
end
