# frozen_string_literal: true

class CreateSubscriptionSeatAssignments < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  UNIQUE_INDEX_NAME = 'uniq_idx_subscription_seat_assignments_on_namespace_and_user'

  def change
    create_table :subscription_seat_assignments do |t| # rubocop:disable Migration/EnsureFactoryForTable -- https://gitlab.com/gitlab-org/gitlab/-/issues/468630
      t.bigint :namespace_id, null: false
      t.bigint :user_id, null: false
      t.datetime_with_timezone :last_activity_on, null: true

      t.timestamps_with_timezone null: false

      t.index [:namespace_id, :user_id], unique: true, name: UNIQUE_INDEX_NAME
      t.index :user_id
    end
  end
end
