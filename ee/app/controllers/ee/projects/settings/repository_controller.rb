module EE
  module Projects
    module Settings
      module RepositoryController
        extend ActiveSupport::Concern

        prepended do
          before_action :push_rule, only: [:show]
          before_action :remote_mirror, only: [:show]
        end

        private

        def push_rule
          return unless project.feature_available?(:push_rules)

          project.create_push_rule unless project.push_rule
          @push_rule = project.push_rule # rubocop:disable Gitlab/ModuleWithInstanceVariables
        end

        def remote_mirror
          return unless project.feature_available?(:repository_mirrors)

          @remote_mirror = project.remote_mirrors.build # rubocop:disable Gitlab/ModuleWithInstanceVariables
        end

        # rubocop:disable Gitlab/ModuleWithInstanceVariables
        def acces_levels_options
          super.merge(
            selected_merge_access_levels: @protected_branch.merge_access_levels.map { |access_level| access_level.user_id || access_level.access_level },
            selected_push_access_levels: @protected_branch.push_access_levels.map { |access_level| access_level.user_id || access_level.access_level },
            selected_create_access_levels: @protected_tag.create_access_levels.map { |access_level| access_level.user_id || access_level.access_level }
          )
        end
        # rubocop:enable Gitlab/ModuleWithInstanceVariables

        def load_gon_index
          super

          gon.push(current_project_id: project.id) if project
        end
      end
    end
  end
end
