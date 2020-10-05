# frozen_string_literal: true

module Admin
  class PropagateServiceTemplate
    include PropagateService

    def propagate
      return unless integration.active?

      create_integration_for_projects_without_integration
    end
  end
end
