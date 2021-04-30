# frozen_string_literal: true

class InitializeConversionOfPushEventPayloadsEventIdToBigint < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    # Foreign key that references events.id
    # Also Primary key of the push_event_payloads table
    initialize_conversion_of_integer_to_bigint :push_event_payloads, :event_id, primary_key: :event_id
  end

  def down
    trigger_name = rename_trigger_name(:push_event_payloads, :event_id, :event_id_convert_to_bigint)

    remove_rename_triggers :push_event_payloads, trigger_name

    remove_column :push_event_payloads, :event_id_convert_to_bigint
  end
end
