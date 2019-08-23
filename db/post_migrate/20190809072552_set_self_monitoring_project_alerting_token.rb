# frozen_string_literal: true

class SetSelfMonitoringProjectAlertingToken < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  module Migratable
    module Alerting
      class ProjectAlertingSetting < ApplicationRecord
        self.table_name = 'project_alerting_settings'

        belongs_to :project

        validates :token, presence: true

        attr_encrypted :token,
          mode: :per_attribute_iv,
          key: Settings.attr_encrypted_db_key_base_truncated,
          algorithm: 'aes-256-gcm'

        before_validation :ensure_token

        private

        def ensure_token
          self.token ||= generate_token
        end

        def generate_token
          SecureRandom.hex
        end
      end
    end

    class Project < ApplicationRecord
      has_one :alerting_setting, inverse_of: :project, class_name: 'Alerting::ProjectAlertingSetting'
    end

    class ApplicationSetting < ApplicationRecord
      self.table_name = 'application_settings'

      belongs_to :instance_administration_project, class_name: 'Project'

      def self.current_without_cache
        last
      end
    end
  end

  def setup_alertmanager_token(project)
    return unless License.feature_available?(:prometheus_alerts)

    project.create_alerting_setting!
  end

  def up
    Gitlab.ee do
      project = Migratable::ApplicationSetting.current_without_cache&.instance_administration_project

      if project
        setup_alertmanager_token(project)
      end
    end
  end

  def down
    Gitlab.ee do
      Migratable::ApplicationSetting.current_without_cache
        &.instance_administration_project
        &.alerting_setting
        &.destroy!
    end
  end
end
