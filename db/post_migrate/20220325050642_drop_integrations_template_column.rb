# frozen_string_literal: true

class DropIntegrationsTemplateColumn < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    remove_column :integrations, :template, :boolean, default: false
  end
end
