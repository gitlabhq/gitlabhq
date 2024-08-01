# frozen_string_literal: true

class RemoveSignInTextAndHelpText < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def up
    remove_column :application_settings, :sign_in_text
    remove_column :application_settings, :help_text
  end

  def down
    add_column :application_settings, :sign_in_text, :text
    add_column :application_settings, :help_text, :text
  end
end
