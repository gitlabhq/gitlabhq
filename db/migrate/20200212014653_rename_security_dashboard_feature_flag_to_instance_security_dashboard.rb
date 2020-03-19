# frozen_string_literal: true

class RenameSecurityDashboardFeatureFlagToInstanceSecurityDashboard < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  class FeatureGate < ApplicationRecord
    self.table_name = 'feature_gates'
  end

  def up
    security_dashboard_feature = FeatureGate.find_by(feature_key: :security_dashboard, key: :boolean)

    if security_dashboard_feature.present?
      FeatureGate.safe_find_or_create_by!(
        feature_key: :instance_security_dashboard,
        key: :boolean,
        value: security_dashboard_feature.value
      )
    end
  end

  def down
    FeatureGate.find_by(feature_key: :instance_security_dashboard, key: :boolean)&.delete
  end
end
