# frozen_string_literal: true

class UpdateWikiPageMaxContentBytesTo5Megabytes < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute <<-SQL
      UPDATE application_settings
      SET wiki_page_max_content_bytes = 5242880
      WHERE wiki_page_max_content_bytes = 52428800
    SQL
  end

  def down
    # no-op
  end
end
