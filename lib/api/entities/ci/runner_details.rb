# frozen_string_literal: true

module API
  module Entities
    module Ci
      class RunnerDetails < Runner
        expose :tag_list
        expose :run_untagged
        expose :locked
        expose :maximum_timeout
        expose :access_level
        expose :version, :revision, :platform, :architecture
        expose :contacted_at

        # rubocop: disable CodeReuse/ActiveRecord
        expose :projects, with: Entities::BasicProjectDetails do |runner, options|
          if options[:current_user].admin? # rubocop: disable Cop/UserAdmin
            runner.projects
          else
            options[:current_user].authorized_projects.where(id: runner.projects)
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
        # rubocop: disable CodeReuse/ActiveRecord
        expose :groups, with: Entities::BasicGroupDetails do |runner, options|
          if options[:current_user].admin? # rubocop: disable Cop/UserAdmin
            runner.groups
          else
            options[:current_user].authorized_groups.where(id: runner.groups)
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
