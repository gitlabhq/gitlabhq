module Projects
  module Settings
    class MembersController < Projects::ApplicationController
      include SortingHelper

      def show
        @sort = params[:sort].presence || sort_value_name
        @group_links = @project.project_group_links

        @skip_groups = @group_links.pluck(:group_id)
        @skip_groups << @project.namespace_id unless @project.personal?
        @skip_groups += @project.group.ancestors.pluck(:id) if @project.group

        @project_members = MembersFinder.new(@project, current_user).execute

        if params[:search].present?
          @project_members = @project_members.joins(:user).merge(User.search(params[:search]))
          @group_links = @group_links.where(group_id: @project.invited_groups.search(params[:search]).select(:id))
        end

        @project_members = @project_members.sort(@sort).page(params[:page])
        @requesters = AccessRequestsFinder.new(@project).execute(current_user)
        @project_member = @project.project_members.new
      end
    end
  end
end
