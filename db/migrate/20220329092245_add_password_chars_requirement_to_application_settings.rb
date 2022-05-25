# frozen_string_literal: true

class AddPasswordCharsRequirementToApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :application_settings, :password_uppercase_required, :boolean, default: false, null: false
    add_column :application_settings, :password_lowercase_required, :boolean, default: false, null: false
    add_column :application_settings, :password_number_required, :boolean, default: false, null: false
    add_column :application_settings, :password_symbol_required, :boolean, default: false, null: false
  end
end
