# frozen_string_literal: true

module Admin
  class PropagateServiceTemplate
    include PropagateService

    def propagate
      return unless integration.active?

      create_integration_for_projects_without_integration
    end

    private

    def service_hash
      @service_hash ||= integration.to_service_hash
    end
  end
end
