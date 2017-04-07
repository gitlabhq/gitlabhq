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
        {
          selected_merge_access_levels: @protected_branch.merge_access_levels.map { |access_level| access_level.user_id || access_level.access_level },
          selected_push_access_levels: @protected_branch.push_access_levels.map { |access_level| access_level.user_id || access_level.access_level },
          create_access_levels: levels_for_dropdown(ProtectedTag::CreateAccessLevel),
          push_access_levels: levels_for_dropdown(ProtectedBranch::PushAccessLevel),
          merge_access_levels: levels_for_dropdown(ProtectedBranch::MergeAccessLevel)
        }
      end

      def levels_for_dropdown(access_level_type)
        roles = access_level_type.human_access_levels.map do |id, text|
          { id: id, text: text, before_divider: true }
        end
        { roles: roles }
      end

      def protectable_tags_for_dropdown
        { open_tags: ProtectableDropdown.new(@project, :tags).hash }
      end

      def protectable_branches_for_dropdown
        { open_branches: ProtectableDropdown.new(@project, :branches).hash }
      end

      def load_gon_index
        gon.push(protectable_tags_for_dropdown)
        gon.push(protectable_branches_for_dropdown)
        gon.push(access_levels_options)
        gon.push(current_project_id: @project.id) if @project
      end
    end
  end
end
