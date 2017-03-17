module Projects
  module Settings
    class RepositoryController < Projects::ApplicationController
      before_action :authorize_admin_project!
      before_action :remote_mirror, only: [:show]

      def show
        @deploy_keys = DeployKeysPresenter.new(@project, current_user: current_user)

        define_protected_refs

        project.create_push_rule unless project.push_rule
        @push_rule = project.push_rule
      end

      private

      def remote_mirror
        @remote_mirror = @project.remote_mirrors.first_or_initialize
      end

      def define_protected_refs
        @protected_branches = @project.protected_branches.order(:name).page(params[:page])
        @protected_tags = @project.protected_tags.order(:name).page(params[:page])
        @protected_branch = @project.protected_branches.new
        @protected_tag = @project.protected_tags.new
        load_gon_index
      end

      def access_levels_options
        #TODO: consider protected tags
        #TODO: Refactor ProtectedBranch::PushAccessLevel so it doesn't mention branches
        {
          push_access_levels: {
            roles: ProtectedBranch::PushAccessLevel.human_access_levels.map do |id, text|
              { id: id, text: text, before_divider: true }
            end
          },
          merge_access_levels: {
            roles: ProtectedBranch::MergeAccessLevel.human_access_levels.map do |id, text|
              { id: id, text: text, before_divider: true }
            end
          },
          selected_merge_access_levels: @protected_branch.merge_access_levels.map { |access_level| access_level.user_id || access_level.access_level },
          selected_push_access_levels: @protected_branch.push_access_levels.map { |access_level| access_level.user_id || access_level.access_level }
        }
      end

      #TODO: Move to Protections::TagMatcher.new(project).unprotected
      def unprotected_tags
        exact_protected_tag_names = @project.protected_tags.reject(&:wildcard?).map(&:name)
        tag_names = @project.repository.tags.map(&:name)
        non_open_tag_names = Set.new(exact_protected_tag_names).intersection(Set.new(tag_names))
        @project.repository.tags.reject { |tag| non_open_tag_names.include? tag.name }
      end

      def unprotected_tags_hash
        tags = unprotected_tags.map { |tag| { text: tag.name, id: tag.name, title: tag.name } }
        { open_tags: tags }
      end

      def open_branches
        branches = @project.open_branches.map { |br| { text: br.name, id: br.name, title: br.name } }
        { open_branches: branches }
      end

      def load_gon_index
        gon.push(open_branches)
        gon.push(unprotected_tags_hash)
        gon.push(access_levels_options)
        gon.push(current_project_id: @project.id) if @project
      end
    end
  end
end
