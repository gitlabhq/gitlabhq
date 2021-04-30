# frozen_string_literal: true

class InitializeConversionOfCiBuildNeedsToBigint < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    initialize_conversion_of_integer_to_bigint :ci_build_needs, :build_id
  end

  def down
    trigger_name = rename_trigger_name(:ci_build_needs, :build_id, :build_id_convert_to_bigint)

    remove_rename_triggers :ci_build_needs, trigger_name

    remove_column :ci_build_needs, :build_id_convert_to_bigint
  end
end
