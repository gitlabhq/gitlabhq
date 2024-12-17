# frozen_string_literal: true

class AddCompositeIdentityEnforcedToUsers < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :users, :composite_identity_enforced, :boolean, default: false, null: false # rubocop:disable Migration/PreventAddingColumns -- this column is used in every permission check
  end
end
