# frozen_string_literal: true

class AddWikiAsciidocAllowUriIncludes < Gitlab::Database::Migration[2.1]
  enable_lock_retries!
  def change
    add_column :application_settings, :wiki_asciidoc_allow_uri_includes, :boolean, default: false, null: false
  end
end
