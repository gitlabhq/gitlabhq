# frozen_string_literal: true

class AddVersionUsageDataIdToRawUsageData < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :raw_usage_data, :version_usage_data_id_value, :bigint
  end
end
