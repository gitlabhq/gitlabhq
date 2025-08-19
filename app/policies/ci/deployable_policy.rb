# frozen_string_literal: true

module Ci
  module DeployablePolicy
    extend ActiveSupport::Concern

    included do
      prepend_mod_with('Ci::DeployablePolicy') # rubocop: disable Cop/InjectEnterpriseEditionModule

      condition(:has_outdated_deployment, scope: :subject) do
        @subject.has_outdated_deployment?
      end

      rule { has_outdated_deployment }.policy do
        ::ProjectPolicy::UPDATE_JOB_PERMISSIONS.each { |perm| prevent(perm) }
        ::ProjectPolicy::CLEANUP_JOB_PERMISSIONS.each { |perm| prevent(perm) }
      end
    end
  end
end
