# frozen_string_literal: true

# See https://docs.gitlab.com/development/migration_style_guide/
# for more information on how to write migrations for GitLab.

class DropSecurityTrainingProviders < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  disable_ddl_transaction!

  TABLE_NAME = :security_training_providers

  def up
    drop_table TABLE_NAME, if_exists: true
  end

  def down
    create_table TABLE_NAME, if_not_exists: true do |t|
      t.text :name, null: false
      t.text :description
      t.text :url, null: false
      t.text :logo_url
      t.timestamps_with_timezone null: false

      t.check_constraint 'char_length(url) <= 512', name: 'check_544b3dc935'
      t.check_constraint 'char_length(logo_url) <= 512', name: 'check_6fe222f071'
      t.check_constraint 'char_length(description) <= 512', name: 'check_a8ff21ced5'
      t.check_constraint 'char_length(name) <= 256', name: 'check_dae433eed6'
    end

    add_concurrent_index TABLE_NAME, :name, unique: true,
      name: 'index_security_training_providers_on_unique_name'
  end
end
