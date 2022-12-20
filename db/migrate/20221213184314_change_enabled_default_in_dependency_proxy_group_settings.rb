# frozen_string_literal: true

class ChangeEnabledDefaultInDependencyProxyGroupSettings < Gitlab::Database::Migration[2.0]
  def change
    change_column_default :dependency_proxy_group_settings, :enabled, from: false, to: true
  end
end
