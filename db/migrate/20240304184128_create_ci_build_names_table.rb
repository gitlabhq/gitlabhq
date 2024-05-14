# frozen_string_literal: true

class CreateCiBuildNamesTable < Gitlab::Database::Migration[2.2]
  enable_lock_retries!

  milestone '16.11'

  PRIMARY_KEY = [:build_id, :partition_id]
  OPTIONS = 'PARTITION BY LIST (partition_id)'

  def up
    create_table(:p_ci_build_names, primary_key: PRIMARY_KEY, options: OPTIONS) do |t|
      t.bigint :build_id, null: false
      t.bigint :partition_id, null: false
      t.bigint :project_id, null: false
      t.text :name, null: false, limit: 255

      t.index [:project_id, :build_id]
    end
  end

  def down
    drop_table :p_ci_build_names
  end
end
