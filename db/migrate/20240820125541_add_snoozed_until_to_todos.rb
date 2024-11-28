# frozen_string_literal: true

class AddSnoozedUntilToTodos < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column :todos, :snoozed_until, :datetime_with_timezone # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
  end
end
