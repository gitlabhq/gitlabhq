# frozen_string_literal: true

class CreateDynamicPartitionsSchema < ActiveRecord::Migration[6.0]
  include Gitlab::Database::SchemaHelpers

  DOWNTIME = false

  def up
    execute 'CREATE SCHEMA partitions_dynamic'

    create_comment(:schema, :partitions_dynamic, <<~EOS.strip)
      Schema to hold partitions managed dynamically from the application, e.g. for time space partitioning.
    EOS
  end

  def down
    execute 'DROP SCHEMA partitions_dynamic'
  end
end
