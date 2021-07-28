# frozen_string_literal: true

module HasIntegrations
  extend ActiveSupport::Concern

  class_methods do
    def without_integration(integration)
      integrations = Integration
        .select('1')
        .where("#{Integration.table_name}.project_id = projects.id")
        .where(type: integration.type)

      Project
        .where('NOT EXISTS (?)', integrations)
        .where(pending_delete: false)
        .where(archived: false)
    end
  end
end
