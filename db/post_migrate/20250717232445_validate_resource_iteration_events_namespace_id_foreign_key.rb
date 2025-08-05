# frozen_string_literal: true

class ValidateResourceIterationEventsNamespaceIdForeignKey < Gitlab::Database::Migration[2.3]
  FK_NAME = 'fk_d405f1c11a'

  milestone '18.3'

  def up
    validate_foreign_key :resource_iteration_events, :namespace_id, name: FK_NAME
  end

  def down
    # no-op
  end
end
