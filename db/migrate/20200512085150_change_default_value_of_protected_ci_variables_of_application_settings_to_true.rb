# frozen_string_literal: true

class ChangeDefaultValueOfProtectedCiVariablesOfApplicationSettingsToTrue < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    change_column_default :application_settings, :protected_ci_variables, from: false, to: true
  end
end
