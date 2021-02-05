# frozen_string_literal: true

class AddContextToExperimentSubjects < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :experiment_subjects, :context, :jsonb, default: {}, null: false
  end
end
