# frozen_string_literal: true

class AddAllowImmediateNamespacesDeletionToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    add_column :application_settings, :namespace_deletion_settings, :jsonb, default: {}, null: false
  end
end
