# frozen_string_literal: true

class ChangeWikiPageMaxContentBytesDefaultTo5Megabytes < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    change_column_default :application_settings, :wiki_page_max_content_bytes, from: 52428800, to: 5242880
  end
end
