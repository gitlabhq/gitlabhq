# frozen_string_literal: true

class AddWorkItemsDatesSourcesFixedDatesFields < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  def change
    change_table :work_item_dates_sources do |t|
      t.date :start_date_fixed
      t.date :due_date_fixed
    end
  end
end
