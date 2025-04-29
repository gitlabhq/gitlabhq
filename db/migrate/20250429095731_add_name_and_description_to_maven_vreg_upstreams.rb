# frozen_string_literal: true

class AddNameAndDescriptionToMavenVregUpstreams < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.0'

  TABLE_NAME = :virtual_registries_packages_maven_upstreams

  def up
    with_lock_retries do
      add_column TABLE_NAME, :name, :text, if_not_exists: true, null: false, default: ''
      add_column TABLE_NAME, :description, :text, if_not_exists: true
    end

    add_text_limit TABLE_NAME, :name, 255
    add_text_limit TABLE_NAME, :description, 1024
  end

  def down
    with_lock_retries do
      remove_column TABLE_NAME, :name, if_exists: true
      remove_column TABLE_NAME, :description, if_exists: true
    end
  end
end
