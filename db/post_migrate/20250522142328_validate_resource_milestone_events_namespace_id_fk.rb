# frozen_string_literal: true

class ValidateResourceMilestoneEventsNamespaceIdFk < Gitlab::Database::Migration[2.3]
  FK_NAME = 'fk_2867e9284c'

  milestone '18.1'

  def up
    validate_foreign_key :resource_milestone_events, :namespace_id, name: FK_NAME
  end

  def down
    # no-op
  end
end
