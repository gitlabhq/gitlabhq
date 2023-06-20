# frozen_string_literal: true

class AddDiagramsnetTextLimit < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :diagramsnet_url, 2048
  end

  def down
    remove_text_limit :application_settings, :diagramsnet_url
  end
end
