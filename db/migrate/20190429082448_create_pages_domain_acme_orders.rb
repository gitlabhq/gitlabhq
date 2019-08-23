# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreatePagesDomainAcmeOrders < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    # rubocop:disable Migration/AddLimitToStringColumns
    create_table :pages_domain_acme_orders do |t|
      t.references :pages_domain, null: false, index: true, foreign_key: { on_delete: :cascade }, type: :integer

      t.datetime_with_timezone :expires_at, null: false
      t.timestamps_with_timezone null: false

      t.string :url, null: false

      t.string :challenge_token, null: false, index: true
      t.text :challenge_file_content, null: false

      t.text :encrypted_private_key, null: false
      t.text :encrypted_private_key_iv, null: false
    end
    # rubocop:enable Migration/AddLimitToStringColumns
  end
end
