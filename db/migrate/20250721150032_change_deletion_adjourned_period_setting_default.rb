# frozen_string_literal: true

class ChangeDeletionAdjournedPeriodSettingDefault < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    change_column_default :application_settings, :deletion_adjourned_period, from: 7, to: 30
  end
end
