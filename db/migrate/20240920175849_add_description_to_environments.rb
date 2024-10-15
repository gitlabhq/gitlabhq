# frozen_string_literal: true

class AddDescriptionToEnvironments < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.5'

  def up
    with_lock_retries do
      add_column :environments, :description, :text, if_not_exists: true
      add_column :environments, :description_html, :text, if_not_exists: true
      add_column :environments, :cached_markdown_version, :integer, if_not_exists: true
    end

    add_text_limit :environments, :description, 10_000
    add_text_limit :environments, :description_html, 50_000
  end

  def down
    with_lock_retries do
      remove_column :environments, :description, if_exists: true
      remove_column :environments, :description_html, if_exists: true
      remove_column :environments, :cached_markdown_version, if_exists: true
    end
  end
end
