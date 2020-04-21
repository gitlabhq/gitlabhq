# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateAwsRoles < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :aws_roles, id: false do |t|
      t.references :user, primary_key: true, default: nil, type: :integer, index: { unique: true }, foreign_key: { on_delete: :cascade }

      t.timestamps_with_timezone null: false

      t.string :role_arn, null: false, limit: 2048
      t.string :role_external_id, null: false, limit: 64

      t.index :role_external_id, unique: true
    end
  end
  # rubocop:enable Migration/PreventStrings
end
