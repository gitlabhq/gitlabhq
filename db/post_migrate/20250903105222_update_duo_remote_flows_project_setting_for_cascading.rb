# frozen_string_literal: true

class UpdateDuoRemoteFlowsProjectSettingForCascading < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def up
    change_column_null :project_settings, :duo_remote_flows_enabled, true
    change_column_default :project_settings, :duo_remote_flows_enabled, from: false, to: nil
  end

  def down
    change_column_default :project_settings, :duo_remote_flows_enabled, from: nil, to: false
    # not reverting `change_column_null` in down as this operation would need prior data cleanup
  end
end
