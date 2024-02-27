# frozen_string_literal: true

class AddOccupiesSeatToMemberRole < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  def change
    add_column :member_roles, :occupies_seat, :boolean, default: false, null: false
  end
end
