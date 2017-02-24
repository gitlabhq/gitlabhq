module EE
  module Ci
    # RegisterBuildService EE mixin
    #
    # This module is intended to encapsulate EE-specific service logic
    # and be included in the `RegisterBuildService` service
    module RegisterBuildService
      extend ActiveSupport::Concern

      def builds_for_shared_runner
        return super unless shared_runner_build_limits_feature_enabled?

        # select projects which have allowed number of shared runner minutes or are public
        super
          .where("projects.visibility_level=? OR (#{builds_check_limit.to_sql})=1",
                ::Gitlab::VisibilityLevel::PUBLIC)
      end

      def builds_check_limit
        ::Namespace.reorder(nil)
          .where('namespaces.id = projects.namespace_id')
          .joins('LEFT JOIN namespace_statistics ON namespace_statistics.namespace_id = namespaces.id')
          .where('COALESCE(namespaces.shared_runners_minutes_limit, ?, 0) = 0 OR ' \
            'COALESCE(namespace_statistics.shared_runners_seconds, 0) < COALESCE(namespaces.shared_runners_minutes_limit, ?, 0) * 60',
                application_shared_runners_minutes, application_shared_runners_minutes)
          .select('1')
      end

      def application_shared_runners_minutes
        current_application_settings.shared_runners_minutes
      end

      def shared_runner_build_limits_feature_enabled?
        ENV['DISABLE_SHARED_RUNNER_BUILD_MINUTES_LIMIT'].to_s != 'true'
      end
    end
  end
end
