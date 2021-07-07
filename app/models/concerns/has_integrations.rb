# frozen_string_literal: true

module HasIntegrations
  extend ActiveSupport::Concern

  class_methods do
    def with_custom_integration_for(integration, page = nil, per = nil)
      custom_integration_project_ids = Integration
        .select(:project_id)
        .where(type: integration.type)
        .where(inherit_from_id: nil)
        .where.not(project_id: nil)
        .page(page)
        .per(per)

      Project.where(id: custom_integration_project_ids)
    end

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
