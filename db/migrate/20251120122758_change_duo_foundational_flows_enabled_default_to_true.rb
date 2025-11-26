# frozen_string_literal: true

class ChangeDuoFoundationalFlowsEnabledDefaultToTrue < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def change
    change_column_default(:application_settings, :duo_foundational_flows_enabled, from: false, to: true)
  end
end
