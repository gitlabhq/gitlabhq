# frozen_string_literal: true

class AddProjectKeyAddressSlugToServiceDeskSettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  def up
    with_lock_retries do
      add_column :service_desk_settings, :project_key_address_slug, :text, if_not_exists: true
    end

    add_text_limit :service_desk_settings, :project_key_address_slug, 500
  end

  def down
    with_lock_retries do
      remove_column :service_desk_settings, :project_key_address_slug, if_exists: true
    end
  end
end
