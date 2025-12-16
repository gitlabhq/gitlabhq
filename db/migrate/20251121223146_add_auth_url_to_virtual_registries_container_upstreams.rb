# frozen_string_literal: true

class AddAuthUrlToVirtualRegistriesContainerUpstreams < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.7'

  def up
    with_lock_retries do
      add_column :virtual_registries_container_upstreams, :auth_url, :text, if_not_exists: true
    end

    add_text_limit :virtual_registries_container_upstreams, :auth_url, 512
  end

  def down
    with_lock_retries do
      remove_column :virtual_registries_container_upstreams, :auth_url, if_exists: true
    end
  end
end
