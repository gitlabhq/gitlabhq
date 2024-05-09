# frozen_string_literal: true

module Integrations
  module Exclusions
    class CreateService < BaseService
      def execute
        super do
          break ServiceResponse.success(payload: []) unless projects.present?

          create_exclusions
        end
      end

      private

      def create_exclusions
        integration_type = Integration.integration_name_to_type(integration_name)
        integration_attrs = projects.map do |project|
          {
            project_id: project.id,
            type_new: integration_type,
            active: false,
            inherit_from_id: nil
          }
        end

        result = Integration.upsert_all(integration_attrs, unique_by: [:project_id, :type_new])
        ServiceResponse.success(payload: Integration.id_in(result.rows.flatten))
      end
    end
  end
end
