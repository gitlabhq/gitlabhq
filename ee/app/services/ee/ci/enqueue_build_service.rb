# frozen_string_literal: true
module EE
  module Ci
    module EnqueueBuildService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(build)
        unless allowed_to_deploy?(build)
          return build.drop!(:protected_environment_failure)
        end

        super
      end

      private

      def allowed_to_deploy?(build)
        # We need to check if Protected Environments feature is available,
        # as evaluating `build.expanded_environment_name` is expensive.
        return true unless project.protected_environments_feature_available?

        project.protected_environment_accessible_to?(build.expanded_environment_name, build.user)
      end
    end
  end
end
