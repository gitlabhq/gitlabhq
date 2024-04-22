# frozen_string_literal: true

module API
  module Entities
    module Ci
      class RunnerDetails < Runner
        include Gitlab::Utils::StrongMemoize

        expose :tag_list
        expose :run_untagged
        expose :locked
        expose :maximum_timeout
        expose :access_level
        # TODO: return nil in 18.0 and remove in v5 https://gitlab.com/gitlab-org/gitlab/-/issues/457128
        expose(:version) { |runner, _options| latest_runner_manager(runner)&.version }
        expose(:revision) { |runner, _options| latest_runner_manager(runner)&.revision }
        expose(:platform) { |runner, _options| latest_runner_manager(runner)&.platform }
        expose(:architecture) { |runner, _options| latest_runner_manager(runner)&.architecture }
        expose :contacted_at
        expose :maintenance_note

        # rubocop: disable CodeReuse/ActiveRecord
        expose :projects, with: Entities::BasicProjectDetails do |runner, options|
          if options[:current_user].can_read_all_resources?
            runner.projects
          else
            options[:current_user].authorized_projects.where(id: runner.runner_projects.pluck(:project_id))
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
        # rubocop: disable CodeReuse/ActiveRecord
        expose :groups, with: Entities::BasicGroupDetails do |runner, options|
          if options[:current_user].can_read_all_resources?
            runner.groups
          else
            options[:current_user].authorized_groups.where(id: runner.runner_namespaces.pluck(:namespace_id))
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def latest_runner_manager(runner)
          strong_memoize_with(:latest_runner_manager, runner) do
            runner.runner_managers.order_contacted_at_desc.first
          end
        end
      end
    end
  end
end
