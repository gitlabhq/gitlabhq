# frozen_string_literal: true

class ChangeDefaultValueForDistroVersion < Gitlab::Database::Migration[2.1]
  def up
    change_column_default :pm_affected_packages, :distro_version, from: nil, to: ''
    change_column_null :pm_affected_packages, :distro_version, false
  end

  def down
    change_column_default :pm_affected_packages, :distro_version, from: '', to: nil
    change_column_null :pm_affected_packages, :distro_version, true
  end
end
