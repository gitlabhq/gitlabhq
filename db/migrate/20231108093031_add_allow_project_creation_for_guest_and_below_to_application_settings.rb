# frozen_string_literal: true

class AddAllowProjectCreationForGuestAndBelowToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '16.6'

  def change
    add_column(:application_settings, :allow_project_creation_for_guest_and_below, :boolean, default: true, null: false)
  end
end
