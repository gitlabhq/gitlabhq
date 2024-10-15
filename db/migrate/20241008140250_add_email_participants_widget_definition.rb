# frozen_string_literal: true

# Renamed from `db/migrate/20240812081354_add_email_participants_widget_to_work_item_types.rb` which
# which was introduced in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162411
# but has been reverted with https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165219
# because of a renamed index.
class AddEmailParticipantsWidgetDefinition < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!
  milestone '17.6'

  class WorkItemType < MigrationRecord
    self.table_name = 'work_item_types'
  end

  class WidgetDefinition < MigrationRecord
    self.table_name = 'work_item_widget_definitions'
  end

  WIDGET_NAME = 'Email participants'
  WIDGET_ENUM_VALUE = 25
  WORK_ITEM_TYPES = %w[
    Incident
    Issue
    Ticket
  ].freeze

  def up
    widgets = WorkItemType.where(name: WORK_ITEM_TYPES).map do |type|
      { work_item_type_id: type.id, name: WIDGET_NAME, widget_type: WIDGET_ENUM_VALUE }
    end

    return if widgets.empty?

    # We might have installations that already received this migration.
    # Using upsert would update their records, but we can also skip it.
    WidgetDefinition.upsert_all(
      widgets,
      on_duplicate: :skip
    )
  end

  def down
    # Although there might be installations that previously had definitions for this widget
    # we should be fine with removing these on `down` because it introduced an invalid
    # state anyway (due to the revert).
    WidgetDefinition.where(widget_type: WIDGET_ENUM_VALUE).delete_all
  end
end
