# frozen_string_literal: true

class CreateStaticPartitionsSchema < ActiveRecord::Migration[6.0]
  include Gitlab::Database::SchemaHelpers

  DOWNTIME = false

  def up
    execute 'CREATE SCHEMA gitlab_partitions_static'

    create_comment(:schema, :gitlab_partitions_static, <<~EOS.strip)
      Schema to hold static partitions, e.g. for hash partitioning
    EOS
  end

  def down
    execute 'DROP SCHEMA gitlab_partitions_static'
  end
end
