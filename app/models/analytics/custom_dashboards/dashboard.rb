# frozen_string_literal: true

module Analytics
  module CustomDashboards
    class Dashboard < ApplicationRecord
      self.table_name = 'custom_dashboards'

      belongs_to :namespace, optional: true
      belongs_to :organization, class_name: 'Organizations::Organization', optional: false

      belongs_to :created_by, class_name: 'User', optional: false
      belongs_to :updated_by, class_name: 'User', optional: true

      has_one :search_data,
        class_name: 'Analytics::CustomDashboards::SearchData',
        foreign_key: :custom_dashboard_id,
        inverse_of: :dashboard
      has_many :dashboard_versions,
        class_name: 'Analytics::CustomDashboards::DashboardVersion',
        foreign_key: :custom_dashboard_id,
        inverse_of: :dashboard

      validates :name, presence: true, length: { maximum: 255 }
      validates :description, length: { maximum: 2048 }
      validates :config, presence: true
      validates :config, json_schema: { filename: 'custom_dashboard_config', size_limit: 64.kilobytes }
      validate :config_must_be_json_object

      after_update :create_config_version, if: :saved_change_to_config?

      private

      def config_must_be_json_object
        errors.add(:config, 'must be a JSON object') unless config.is_a?(Hash)
      end

      def create_config_version
        last_version = dashboard_versions.order(version_number: :desc).first
        next_version_number = last_version ? last_version.version_number + 1 : 1

        dashboard_versions.create!(
          organization_id: organization_id,
          version_number: next_version_number,
          config: config,
          updated_by_id: updated_by_id
        )
      end
    end
  end
end
