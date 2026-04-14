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

      condition(:has_access_to_protected_environment) do
        user_has_protected_environment_access?
      end

      rule { has_outdated_deployment }.policy do
        prevent(*all_job_write_abilities)
      end

      rule { ~has_access_to_protected_environment }.policy do
        prevent(:_update_protected_job)
      end

      private

      # overridden in EE
      def user_has_protected_environment_access?
        false
      end
    end
  end
end
