# frozen_string_literal: true

module Integration
  extend ActiveSupport::Concern

  class_methods do
    def with_custom_integration_for(integration, page = nil, per = nil)
      custom_integration_project_ids = Service
        .where(type: integration.type)
        .where(inherit_from_id: nil)
        .distinct # Required until https://gitlab.com/gitlab-org/gitlab/-/issues/207385
        .page(page)
        .per(per)
        .pluck(:project_id)

      Project.where(id: custom_integration_project_ids)
    end
  end
end
