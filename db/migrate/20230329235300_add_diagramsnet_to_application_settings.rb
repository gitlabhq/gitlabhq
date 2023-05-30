# frozen_string_literal: true

class AddDiagramsnetToApplicationSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20230406115900_add_diagramsnet_text_limit.rb
  def change
    add_column :application_settings, :diagramsnet_enabled, :boolean, default: true, null: false
    add_column :application_settings, :diagramsnet_url, :text, default: 'https://embed.diagrams.net'
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
