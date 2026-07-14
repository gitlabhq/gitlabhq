# frozen_string_literal: true

module Groups
  module Observability
    class SetupController < BaseController
      include ::Observability::SetupActions

      private

      def observability_namespace
        group
      end
    end
  end
end
