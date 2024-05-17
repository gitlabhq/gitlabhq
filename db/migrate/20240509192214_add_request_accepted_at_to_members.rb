# frozen_string_literal: true

class AddRequestAcceptedAtToMembers < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def change
    add_column :members, :request_accepted_at, :datetime_with_timezone, null: true
  end
end
