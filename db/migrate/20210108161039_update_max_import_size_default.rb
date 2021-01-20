# frozen_string_literal: true

class UpdateMaxImportSizeDefault < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    change_column_default(:application_settings, :max_import_size, from: 50, to: 0)
  end
end
