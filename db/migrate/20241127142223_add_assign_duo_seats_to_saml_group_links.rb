# frozen_string_literal: true

class AddAssignDuoSeatsToSamlGroupLinks < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  def up
    add_column :saml_group_links, :assign_duo_seats, :boolean, null: false, default: false, if_not_exists: true
  end

  def down
    remove_column :saml_group_links, :assign_duo_seats
  end
end
