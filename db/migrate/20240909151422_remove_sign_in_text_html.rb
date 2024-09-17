# frozen_string_literal: true

class RemoveSignInTextHtml < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def up
    remove_column :application_settings, :sign_in_text_html # rubocop:disable Migration/RemoveColumn -- We need to remove this unused column
  end

  def down
    add_column :application_settings, :sign_in_text_html, :text
  end
end
