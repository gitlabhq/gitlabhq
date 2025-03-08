# frozen_string_literal: true

class AddProviderToSamlGroupLinks < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  def up
    add_column :saml_group_links, :provider, :text, null: true, if_not_exists: true
    add_text_limit :saml_group_links, :provider, 255
  end

  def down
    remove_column :saml_group_links, :provider
  end
end
