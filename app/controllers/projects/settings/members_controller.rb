module Projects
  module Settings
    class MembersController < Projects::ApplicationController
      include SortingHelper

      def show
        @sort = params[:sort].presence || sort_value_name
        @group_links = @project.project_group_links

        @project_members = @project.project_members
        @project_members = @project_members.non_invite unless can?(current_user, :admin_project, @project)

        group = @project.group

        # group links
        @group_links = @project.project_group_links.all

        @skip_groups = @group_links.pluck(:group_id)
        @skip_groups << @project.namespace_id unless @project.personal?

        if group
          # We need `.where.not(user_id: nil)` here otherwise when a group has an
          # invitee, it would make the following query return 0 rows since a NULL
          # user_id would be present in the subquery
          # See http://stackoverflow.com/questions/129077/not-in-clause-and-null-values
          group_members = MembersFinder.new(@project_members, group).execute(current_user)
        end

        if params[:search].present?
          user_ids = @project.users.search(params[:search]).select(:id)
          @project_members = @project_members.where(user_id: user_ids)

          if group_members
            user_ids = group.users.search(params[:search]).select(:id)
            group_members = group_members.where(user_id: user_ids)
          end

          @group_links = @project.project_group_links.where(group_id: @project.invited_groups.search(params[:search]).select(:id))
        end

        wheres = ["members.id IN (#{@project_members.select(:id).to_sql})"]
        wheres << "members.id IN (#{group_members.select(:id).to_sql})" if group_members

        @project_members = Member.
          where(wheres.join(' OR ')).
          sort(@sort).
          page(params[:page])

        @requesters = AccessRequestsFinder.new(@project).execute(current_user)

        @project_member = @project.project_members.new
      end
    end
  end
end
