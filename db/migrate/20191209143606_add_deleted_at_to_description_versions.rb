# frozen_string_literal: true

class AddDeletedAtToDescriptionVersions < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :description_versions, :deleted_at, :datetime_with_timezone
  end
end
