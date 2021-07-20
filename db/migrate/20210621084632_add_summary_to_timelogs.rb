# frozen_string_literal: true

class AddSummaryToTimelogs < ActiveRecord::Migration[6.1]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20210621090030_add_text_limit_to_timelogs_summary
  def change
    add_column :timelogs, :summary, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
