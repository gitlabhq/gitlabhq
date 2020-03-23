# frozen_string_literal: true

class AddMaxPersonalAccessTokenLifetimeToNamespaces < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :namespaces, :max_personal_access_token_lifetime, :integer
    end
  end

  def down
    with_lock_retries do
      remove_column :namespaces, :max_personal_access_token_lifetime
    end
  end
end
