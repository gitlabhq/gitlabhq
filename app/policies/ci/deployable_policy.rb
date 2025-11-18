# frozen_string_literal: true

module Ci
  module DeployablePolicy
    extend ActiveSupport::Concern

    included do
      include Ci::JobAbilities

      prepend_mod_with('Ci::DeployablePolicy') # rubocop: disable Cop/InjectEnterpriseEditionModule

      condition(:has_outdated_deployment, scope: :subject) do
        @subject.has_outdated_deployment?
      end

      # https://docs.gitlab.com/ci/environments/protected_environments/#deployment-only-access-to-protected-environments
      condition(:reporter_has_access_to_protected_environment) do
        reporter_has_access_to_protected_environment?
      end

      rule { has_outdated_deployment }.policy do
        prevent(*all_job_write_abilities)
      end

      private

      # overridden in EE
      def reporter_has_access_to_protected_environment?
        false
      end
    end
  end
end
