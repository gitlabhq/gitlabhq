# frozen_string_literal: true

module Groups
  module Observability
    class SetupController < BaseController
      def show
        if group.observability_group_o11y_setting.present?
          @has_pipelines_since_setup =
            ::Observability::PipelinesSinceSetupExist
              .new(group)
              .execute
          return
        end

        group.build_observability_group_o11y_setting(o11y_service_name: group.id) if provisioning?
      end

      private

      def provisioning?
        params.permit(:provisioning)[:provisioning] == 'true'
      end
    end
  end
end
