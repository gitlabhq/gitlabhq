# frozen_string_literal: true

module Integration
  extend ActiveSupport::Concern

  class_methods do
    def with_custom_integration_compared_to(integration)
      custom_integrations = Service
        .select('1')
        .where(type: integration.type, inherit_from_id: nil)
        .where('services.project_id = projects.id')

      Project.where('EXISTS (?)', custom_integrations)
    end
  end
end
