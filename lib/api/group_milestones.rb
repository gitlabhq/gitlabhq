# frozen_string_literal: true

module API
  class GroupMilestones < ::API::Base
    include MilestoneResponses
    include PaginationParams

    before { authenticate! }

    feature_category :team_planning
    urgency :low

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'List all group milestones' do
        detail 'Lists all group milestones for a specified group.'
        success Entities::Milestone
        tags ['milestones']
      end
      params do
        use :list_params
        optional :include_descendants, type: Grape::API::Boolean,
          desc: 'Include milestones from all subgroups and subprojects'
      end
      route_setting :authorization, permissions: :read_milestone, boundary_type: :group
      get ":id/milestones" do
        list_milestones_for(user_group)
      end

      desc 'Retrieve a group milestone' do
        detail 'Retrieves a specified group milestone.'
        success Entities::Milestone
        tags ['milestones']
      end
      params do
        requires :milestone_id, type: Integer, desc: 'The ID of a group milestone'
      end
      route_setting :authorization, permissions: :read_milestone, boundary_type: :group
      get ":id/milestones/:milestone_id" do
        authorize! :read_group, user_group

        get_milestone_for(user_group)
      end

      desc 'Create a group milestone' do
        detail 'Creates a milestone for the specified group.'
        success Entities::Milestone
        tags ['milestones']
      end
      params do
        requires :title, type: String, desc: 'The title of the milestone'
        use :optional_params
      end
      route_setting :authorization, permissions: :create_milestone, boundary_type: :group
      post ":id/milestones" do
        authorize! :admin_milestone, user_group

        create_milestone_for(user_group)
      end

      desc 'Update a group milestone' do
        detail 'Updates the specified group milestone.'
        success Entities::Milestone
        tags ['milestones']
      end
      params do
        use :update_params
      end
      route_setting :authorization, permissions: :update_milestone, boundary_type: :group
      put ":id/milestones/:milestone_id" do
        authorize! :admin_milestone, user_group

        update_milestone_for(user_group)
      end

      desc 'Delete a group milestone' do
        detail 'Deletes the specified group milestone.'
        success code: 204, message: '204 No Content'
        tags ['milestones']
      end
      route_setting :authorization, permissions: :delete_milestone, boundary_type: :group
      delete ":id/milestones/:milestone_id" do
        authorize! :admin_milestone, user_group

        milestone = user_group.milestones.find(params[:milestone_id])
        Milestones::DestroyService.new(user_group, current_user).execute(milestone)

        no_content!
      end

      desc 'List all issues assigned to a single milestone' do
        detail 'Lists all issues assigned to a specified group milestone.'
        success Entities::IssueBasic
        tags ['milestones']
      end
      params do
        requires :milestone_id, type: Integer, desc: 'The ID of a group milestone'
        use :pagination
      end
      route_setting :authorization, permissions: :read_milestone_issue, boundary_type: :group
      get ":id/milestones/:milestone_id/issues" do
        milestone_issuables_for(user_group, :issue)
      end

      desc 'List all merge requests assigned to a single milestone' do
        detail 'Lists all merge requests assigned to a specified group milestone.'
        success Entities::MergeRequestBasic
        tags ['milestones']
      end
      params do
        requires :milestone_id, type: Integer, desc: 'The ID of a group milestone'
        use :pagination
      end
      route_setting :authorization, permissions: :read_milestone_merge_request, boundary_type: :group
      get ':id/milestones/:milestone_id/merge_requests' do
        milestone_issuables_for(user_group, :merge_request)
      end
    end
  end
end

API::GroupMilestones.prepend_mod_with('API::GroupMilestones')
