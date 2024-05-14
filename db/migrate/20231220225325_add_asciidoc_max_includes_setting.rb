# frozen_string_literal: true

class AddAsciidocMaxIncludesSetting < Gitlab::Database::Migration[2.2]
  enable_lock_retries!

  milestone '16.10'

  def up
    add_column :application_settings, :asciidoc_max_includes, :smallint, default: 32, null: false
  end

  def down
    remove_column :application_settings, :asciidoc_max_includes
  end
end
