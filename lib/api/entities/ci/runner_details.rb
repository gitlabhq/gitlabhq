# frozen_string_literal: true

module API
  module Entities
    module Ci
      class RunnerDetails < Runner
        include Gitlab::Utils::StrongMemoize

        # NOTE: instance runners are exposed by default to any authenticated user,
        # remember to protect any sensitive fields
        expose :tag_list
        expose :run_untagged
        expose :locked
        expose :maximum_timeout
        expose :access_level
        # TODO: remove in v5 https://gitlab.com/gitlab-org/gitlab/-/issues/457128
        expose(:version) { |runner, _options| latest_runner_manager(runner)&.version }
        expose(:revision) { |runner, _options| latest_runner_manager(runner)&.revision }
        expose(:platform) { |runner, _options| latest_runner_manager(runner)&.platform }
        expose(:architecture) { |runner, _options| latest_runner_manager(runner)&.architecture }
        expose :contacted_at
        expose :maintenance_note do |runner, options|
          runner.maintenance_note if options[:current_user].can?(:update_runner, runner)
        end

        expose :projects, with: Entities::BasicProjectDetails, if: ->(_, options) {
          options[:include_projects]
        } do |runner, options|
          next runner.projects if options[:current_user].can_read_all_resources?

          options[:current_user].authorized_projects.id_in(runner.project_ids)
        end
        expose :groups, with: Entities::BasicGroupDetails do |runner, options|
          next runner.groups if options[:current_user].can_read_all_resources?

          options[:current_user].authorized_groups.id_in(runner.namespace_ids)
        end

        def latest_runner_manager(runner)
          strong_memoize_with(:latest_runner_manager, runner) do
            runner.runner_managers.order_contacted_at_desc.first
          end
        end
      end
    end
  end
end
