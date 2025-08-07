# frozen_string_literal: true

class ValidateResourceStateEventsNamespaceIdForeignKey < Gitlab::Database::Migration[2.3]
  FK_NAME = 'fk_20262abeba'

  milestone '18.3'

  def up
    validate_foreign_key :resource_state_events, :namespace_id, name: FK_NAME
  end

  def down
    # no-op
  end
end
