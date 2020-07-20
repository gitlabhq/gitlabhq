# frozen_string_literal: true

class CreateCiInstanceVariables < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:ci_instance_variables)
      create_table :ci_instance_variables do |t|
        t.integer :variable_type, null: false, limit: 2, default: 1
        t.boolean :masked, default: false, allow_null: false
        t.boolean :protected, default: false, allow_null: false
        t.text :key, null: false
        t.text :encrypted_value
        t.text :encrypted_value_iv

        t.index [:key], name: 'index_ci_instance_variables_on_key', unique: true, using: :btree
      end
    end

    add_text_limit(:ci_instance_variables, :key, 255)
    add_text_limit(:ci_instance_variables, :encrypted_value, 1024)
    add_text_limit(:ci_instance_variables, :encrypted_value_iv, 255)
  end

  def down
    drop_table :ci_instance_variables
  end
end
