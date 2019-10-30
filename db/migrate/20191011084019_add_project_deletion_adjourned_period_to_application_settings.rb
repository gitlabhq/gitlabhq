# frozen_string_literal: true

class AddProjectDeletionAdjournedPeriodToApplicationSettings < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  DEFAULT_NUMBER_OF_DAYS_BEFORE_REMOVAL = 7

  def change
    add_column :application_settings, :deletion_adjourned_period, :integer, default: DEFAULT_NUMBER_OF_DAYS_BEFORE_REMOVAL, null: false
  end
end
