# frozen_string_literal: true

class AddLimitMetricTypeToList < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :lists, :limit_metric, :string, limit: 20 # rubocop:disable Migration/PreventStrings
  end
end
