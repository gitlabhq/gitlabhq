class CreateApplicationSettingTerms < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  def change
    create_table :application_setting_terms do |t|
      t.integer :cached_markdown_version
      t.text :terms, null: false
      t.text :terms_html
    end
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
