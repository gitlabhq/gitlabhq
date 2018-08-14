class CreateApplicationSettingTerms < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :application_setting_terms do |t|
      t.integer :cached_markdown_version
      t.text :terms, null: false
      t.text :terms_html
    end
  end
end
