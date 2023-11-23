# frozen_string_literal: true

class AddCanCreateOrganizationToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  def change
    add_column(:application_settings, :can_create_organization, :boolean, default: true, null: false)
  end
end
