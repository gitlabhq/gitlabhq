# frozen_string_literal: true

class InitializeConversionOfEventsIdToBigint < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    # Initialize the conversion of events.id to bigint
    # Primary Key of the Events table
    initialize_conversion_of_integer_to_bigint :events, :id
  end

  def down
    trigger_name = rename_trigger_name(:events, :id, :id_convert_to_bigint)

    remove_rename_triggers :events, trigger_name

    remove_column :events, :id_convert_to_bigint
  end
end
