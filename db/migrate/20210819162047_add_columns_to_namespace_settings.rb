# frozen_string_literal: true

class AddColumnsToNamespaceSettings < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :namespace_settings, :setup_for_company, :boolean
      add_column :namespace_settings, :jobs_to_be_done, :smallint
    end
  end

  def down
    with_lock_retries do
      remove_column :namespace_settings, :setup_for_company
      remove_column :namespace_settings, :jobs_to_be_done
    end
  end
end
