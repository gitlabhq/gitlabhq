# frozen_string_literal: true

module API
  module Entities
    class RunnerDetails < Runner
      expose :tag_list
      expose :run_untagged
      expose :locked
      expose :maximum_timeout
      expose :access_level
      expose :version, :revision, :platform, :architecture
      expose :contacted_at

      # @deprecated in 12.10 https://gitlab.com/gitlab-org/gitlab/-/issues/214320
      # will be removed by 13.0 https://gitlab.com/gitlab-org/gitlab/-/issues/214322
      expose :token, if: lambda { |runner, options| options[:current_user].admin? || !runner.instance_type? }

      # rubocop: disable CodeReuse/ActiveRecord
      expose :projects, with: Entities::BasicProjectDetails do |runner, options|
        if options[:current_user].admin?
          runner.projects
        else
          options[:current_user].authorized_projects.where(id: runner.projects)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
      # rubocop: disable CodeReuse/ActiveRecord
      expose :groups, with: Entities::BasicGroupDetails do |runner, options|
        if options[:current_user].admin?
          runner.groups
        else
          options[:current_user].authorized_groups.where(id: runner.groups)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
