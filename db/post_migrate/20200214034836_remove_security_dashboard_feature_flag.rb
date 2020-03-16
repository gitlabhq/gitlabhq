# frozen_string_literal: true

class RemoveSecurityDashboardFeatureFlag < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  class FeatureGate < ApplicationRecord
    self.table_name = 'feature_gates'
  end

  def up
    FeatureGate.find_by(feature_key: :security_dashboard, key: :boolean)&.delete
  end

  def down
    instance_security_dashboard_feature = FeatureGate.find_by(feature_key: :instance_security_dashboard, key: :boolean)

    if instance_security_dashboard_feature.present?
      FeatureGate.safe_find_or_create_by!(
        feature_key: :security_dashboard,
        key: instance_security_dashboard_feature.key,
        value: instance_security_dashboard_feature.value
      )
    end
  end
end
