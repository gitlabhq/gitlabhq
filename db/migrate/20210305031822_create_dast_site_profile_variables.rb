# frozen_string_literal: true

class CreateDastSiteProfileVariables < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    table_comment = { owner: 'group::dynamic analysis', description: 'Secret variables used in DAST on-demand scans' }

    encrypted_value_constraint_name = check_constraint_name(:dast_site_profile_secret_variables, 'encrypted_value', 'max_length')
    encrypted_value_iv_constraint_name = check_constraint_name(:dast_site_profile_secret_variables, 'encrypted_value_iv', 'max_length')

    create_table_with_constraints :dast_site_profile_secret_variables, comment: table_comment.to_json do |t|
      t.references :dast_site_profile, null: false, foreign_key: { on_delete: :cascade }, index: false

      t.timestamps_with_timezone

      t.integer :variable_type, null: false, default: 1, limit: 2

      t.text :key, null: false
      t.binary :encrypted_value, null: false
      t.binary :encrypted_value_iv, null: false, unique: true

      t.index [:dast_site_profile_id, :key], unique: true, name: :index_site_profile_secret_variables_on_site_profile_id_and_key

      t.text_limit :key, 255

      # This does not currently have first-class support via create_table_with_constraints
      t.check_constraint encrypted_value_constraint_name, 'length(encrypted_value) <= 13352'
      t.check_constraint encrypted_value_iv_constraint_name, 'length(encrypted_value_iv) <= 17'
    end
  end

  def down
    drop_table :dast_site_profile_secret_variables
  end
end
