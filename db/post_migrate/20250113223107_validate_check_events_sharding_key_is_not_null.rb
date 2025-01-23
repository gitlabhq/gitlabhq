# frozen_string_literal: true

class ValidateCheckEventsShardingKeyIsNotNull < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    validate_check_constraint(:events, :check_events_sharding_key_is_not_null)
  end

  def down
    # no-op
  end
end
