# frozen_string_literal: true

module Integrations
  module Instance
    class Integration < ApplicationRecord
      include IgnorableColumns
      include Integrations::Base::Integration

      self.table_name = 'instance_integrations'
      self.inheritance_column = :type_new # rubocop:disable Database/AvoidInheritanceColumn -- supporting instance integrations migration

      ignore_column :type, remove_with: '17.7', remove_after: '2024-12-02'

      has_one :issue_tracker_data,
        autosave: true,
        inverse_of: :instance_integration,
        foreign_key: :instance_integration_id,
        class_name: 'Integrations::IssueTrackerData'

      has_one :jira_tracker_data,
        autosave: true,
        inverse_of: :instance_integration,
        foreign_key: :instance_integration_id,
        class_name: 'Integrations::JiraTrackerData'

      has_one :zentao_tracker_data,
        autosave: true,
        inverse_of: :instance_integration,
        foreign_key: :instance_integration_id,
        class_name: 'Integrations::ZentaoTrackerData'

      def instance_level?
        true
      end

      def group_level?
        false
      end

      def project_level?
        false
      end
    end
  end
end
