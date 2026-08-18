# frozen_string_literal: true

module Groups
  module Observability
    class SetupController < BaseController
      include ::Observability::SetupActions

      private

      def observability_namespace
        group
      end

      def observability_context_label
        'group'
      end
    end
  end
end
