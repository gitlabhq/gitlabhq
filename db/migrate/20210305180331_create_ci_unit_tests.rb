# frozen_string_literal: true

class CreateCiUnitTests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:ci_unit_tests)
      create_table :ci_unit_tests do |t|
        t.bigint :project_id, null: false
        t.text :key_hash, null: false
        t.text :name, null: false
        t.text :suite_name, null: false

        t.index [:project_id, :key_hash], unique: true
        # NOTE: FK for projects will be added on a separate migration as per guidelines
      end
    end

    add_text_limit :ci_unit_tests, :key_hash, 64
    add_text_limit :ci_unit_tests, :name, 255
    add_text_limit :ci_unit_tests, :suite_name, 255
  end

  def down
    drop_table :ci_unit_tests
  end
end
