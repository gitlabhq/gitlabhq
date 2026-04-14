# frozen_string_literal: true

class ConvertTableToListPartitioningForCiBuildNeeds < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  # Will be retried in db/post_migrate/20260402135605_convert_table_to_list_partitioning_for_ci_build_needs2.rb
  def up; end
  def down; end
end
