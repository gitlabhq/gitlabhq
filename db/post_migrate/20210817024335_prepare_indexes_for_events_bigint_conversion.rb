# frozen_string_literal: true

class PrepareIndexesForEventsBigintConversion < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  TABLE_NAME = 'events'

  def up
    prepare_async_index TABLE_NAME, :id_convert_to_bigint, unique: true,
                                                           name: :index_events_on_id_convert_to_bigint

    prepare_async_index TABLE_NAME, [:project_id, :id_convert_to_bigint],
      name: :index_events_on_project_id_and_id_convert_to_bigint

    prepare_async_index TABLE_NAME, [:project_id, :id_convert_to_bigint],
                        order: { id_convert_to_bigint: :desc },
                        where: 'action = 7', name: :index_events_on_project_id_and_id_bigint_desc_on_merged_action
  end

  def down
    unprepare_async_index_by_name TABLE_NAME, :index_events_on_id_convert_to_bigint
    unprepare_async_index_by_name TABLE_NAME, :index_events_on_project_id_and_id_convert_to_bigint
    unprepare_async_index_by_name TABLE_NAME, :index_events_on_project_id_and_id_bigint_desc_on_merged_action
  end
end
