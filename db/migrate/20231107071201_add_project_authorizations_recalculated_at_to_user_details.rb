# frozen_string_literal: true

class AddProjectAuthorizationsRecalculatedAtToUserDetails < Gitlab::Database::Migration[2.2]
  milestone '16.6'
  enable_lock_retries!

  def change
    add_column :user_details, :project_authorizations_recalculated_at, :datetime_with_timezone,
      default: '2010-01-01', null: false
  end
end
