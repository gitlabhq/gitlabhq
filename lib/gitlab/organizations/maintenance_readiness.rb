# frozen_string_literal: true

module Gitlab
  module Organizations
    # Cutover-readiness check for entering the steady `maintenance` state.
    # TODO: checks need to be implemented https://gitlab.com/gitlab-org/gitlab/-/work_items/602822
    class MaintenanceReadiness
      def initialize(organization)
        @organization = organization
      end

      def ready?
        false
      end

      private

      attr_reader :organization
    end
  end
end
