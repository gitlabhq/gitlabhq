# frozen_string_literal: true

class AddWikiPageMaxContentBytesToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :wiki_page_max_content_bytes, :bigint, default: 50.megabytes, null: false
  end
end
