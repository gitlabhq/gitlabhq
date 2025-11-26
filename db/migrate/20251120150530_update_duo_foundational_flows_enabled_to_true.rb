# frozen_string_literal: true

class UpdateDuoFoundationalFlowsEnabledToTrue < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    execute('UPDATE application_settings SET duo_foundational_flows_enabled = true')
  end

  def down
    # no-op
  end
end
