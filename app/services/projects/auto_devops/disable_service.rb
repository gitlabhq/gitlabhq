# frozen_string_literal: true

module Projects
  module AutoDevops
    class DisableService < BaseService
      def execute
        return false unless implicitly_enabled_and_first_pipeline_failure?

        disable_auto_devops
      end

      private

      def implicitly_enabled_and_first_pipeline_failure?
        project.has_auto_devops_implicitly_enabled? &&
          first_pipeline_failure?
      end

      # We're using `limit` to optimize `auto_devops pipeline` query,
      # since we only care about the first element, and using only `.count`
      # is an expensive operation. See
      # https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/21172#note_99037378
      # for more context.
      # rubocop: disable CodeReuse/ActiveRecord
      def first_pipeline_failure?
        auto_devops_pipelines.success.limit(1).count.zero? &&
          auto_devops_pipelines.failed.limit(1).count.nonzero?
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def disable_auto_devops
        project.auto_devops_attributes = { enabled: false }
        project.save!
      end

      def auto_devops_pipelines
        @auto_devops_pipelines ||= project.pipelines.auto_devops_source
      end
    end
  end
end
