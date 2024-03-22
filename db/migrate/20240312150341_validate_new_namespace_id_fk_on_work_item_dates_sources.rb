# frozen_string_literal: true

class ValidateNewNamespaceIdFkOnWorkItemDatesSources < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  NEW_FK_NAME = 'fk_work_item_dates_sources_on_namespace_id'

  # foreign key added in FixWorkItemSourceDatesCascadeOptionOnFkToNamespaceId
  def up
    validate_foreign_key(:work_item_dates_sources, :namespace_id, name: NEW_FK_NAME)
  end

  def down
    # no-op
  end
end
