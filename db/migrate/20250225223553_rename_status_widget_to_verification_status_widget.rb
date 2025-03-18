# frozen_string_literal: true

class RenameStatusWidgetToVerificationStatusWidget < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  milestone '17.10'

  STATUS_WIDGET_TYPE = 11

  def up
    update_column_in_batches(:work_item_widget_definitions, :name, 'Verification status') do |table, query|
      query.where(table[:widget_type].eq(STATUS_WIDGET_TYPE))
    end
  end

  def down
    update_column_in_batches(:work_item_widget_definitions, :name, 'Status') do |table, query|
      query.where(table[:widget_type].eq(STATUS_WIDGET_TYPE))
    end
  end
end
