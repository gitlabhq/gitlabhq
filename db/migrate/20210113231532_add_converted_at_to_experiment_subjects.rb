# frozen_string_literal: true

class AddConvertedAtToExperimentSubjects < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :experiment_subjects, :converted_at, :datetime_with_timezone
  end
end
