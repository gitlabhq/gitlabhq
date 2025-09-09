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
        # TODO: remove in v5 https://gitlab.com/gitlab-org/gitlab/-/issues/457128
        expose(:version) { |runner, _options| latest_runner_manager(runner)&.version }
        expose(:revision) { |runner, _options| latest_runner_manager(runner)&.revision }
        expose(:platform) { |runner, _options| latest_runner_manager(runner)&.platform }
        expose(:architecture) { |runner, _options| latest_runner_manager(runner)&.architecture }
        expose :contacted_at
        expose :maintenance_note do |runner, options|
          runner.maintenance_note if options[:current_user].can?(:update_runner, runner)
        end

        expose :projects, with: Entities::BasicProjectDetails do |runner, options|
          if options[:current_user].can_read_all_resources?
            runner.projects
          else
            options[:current_user].authorized_projects.id_in(runner.project_ids)
          end
        end
        expose :groups, with: Entities::BasicGroupDetails do |runner, options|
          if options[:current_user].can_read_all_resources?
            runner.groups
          else
            options[:current_user].authorized_groups.id_in(runner.namespace_ids)
          end
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
