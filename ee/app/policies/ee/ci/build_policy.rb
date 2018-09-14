# frozen_string_literal: true
module EE
  module Ci
    module BuildPolicy
      extend ActiveSupport::Concern

      prepended do
        condition(:deployable_by_user) { deployable_by_user? }

        rule { ~deployable_by_user }.policy do
          prevent :update_build
        end

        private

        alias_method :current_user, :user
        alias_method :build, :subject

        def deployable_by_user?
          # We need to check if Protected Environments feature is available,
          # as evaluating `build.expanded_environment_name` is expensive.
          return true unless build.project.protected_environments_feature_available?

          build.project.protected_environment_accessible_to?(build.expanded_environment_name, user)
        end
      end
    end
  end
end
