# frozen_string_literal: true

module Projects
  module Observability
    class SetupController < BaseController
      include ::Observability::SetupActions

      private

      def observability_namespace
        project.namespace
      end

      def project_for_export_variable
        project
      end
    end
  end
end
