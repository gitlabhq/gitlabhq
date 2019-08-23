# frozen_string_literal: true

class RemoveKodingFromApplicationSettings < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    remove_column :application_settings, :koding_enabled
    remove_column :application_settings, :koding_url
  end

  def down
    add_column :application_settings, :koding_enabled, :boolean # rubocop:disable Migration/SaferBooleanColumn
    add_column :application_settings, :koding_url, :string # rubocop:disable Migration/AddLimitToStringColumns
  end
end
