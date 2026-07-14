# frozen_string_literal: true

module API
  class ProjectMilestones < ::API::Base
    include PaginationParams
    include MilestoneResponses
    include APIGuard

    before { authenticate! }

    allow_access_with_scope :ai_workflows, if: ->(request) {
      request.get? || request.head?
    }

    feature_category :team_planning
    urgency :low

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'List all project milestones' do
        detail 'Lists all milestones for a specified project.'
        success Entities::Milestone
        tags ['milestones']
      end
      params do
        use :list_params
      end
      route_setting :authorization, permissions: :read_milestone, boundary_type: :project
      get ":id/milestones" do
        authorize! :read_milestone, user_project

        list_milestones_for(user_project)
      end

      desc 'Retrieve a project milestone' do
        detail 'Retrieves a specified project milestone.'
        success Entities::Milestone
        tags ['milestones']
      end
      params do
        requires :milestone_id, type: Integer, desc: 'The ID of a project milestone'
      end
      route_setting :authorization, permissions: :read_milestone, boundary_type: :project
      get ":id/milestones/:milestone_id" do
        authorize! :read_milestone, user_project

        get_milestone_for(user_project)
      end

      desc 'Create a project milestone' do
        detail 'Creates a project milestone.'
        success Entities::Milestone
        tags ['milestones']
      end
      params do
        requires :title, type: String, desc: 'The title of the milestone'
        use :optional_params
      end
      route_setting :authorization, permissions: :create_milestone, boundary_type: :project
      post ":id/milestones" do
        authorize! :admin_milestone, user_project

        create_milestone_for(user_project)
      end

      desc 'Update a project milestone' do
        detail 'Updates a specified project milestone.'
        success Entities::Milestone
        tags ['milestones']
      end
      params do
        use :update_params
      end
      route_setting :authorization, permissions: :update_milestone, boundary_type: :project
      put ":id/milestones/:milestone_id" do
        authorize! :admin_milestone, user_project

        update_milestone_for(user_project)
      end

      desc 'Delete a project milestone' do
        detail 'Deletes a specified project milestone. Only for users with the Planner, Reporter, Developer, ' \
          'Maintainer, or Owner role for the project.'
        tags ['milestones']
        success code: 204
      end
      route_setting :authorization, permissions: :delete_milestone, boundary_type: :project
      delete ":id/milestones/:milestone_id" do
        authorize! :admin_milestone, user_project

        milestone = user_project.milestones.find(params[:milestone_id])
        Milestones::DestroyService.new(user_project, current_user).execute(milestone)

        no_content!
      end

      desc 'List all issues for a project milestone' do
        detail 'Lists all issues assigned to a specified project milestone.'
        success Entities::IssueBasic
        tags ['milestones']
      end
      params do
        requires :milestone_id, type: Integer, desc: 'The ID of a project milestone'
        use :pagination
      end
      route_setting :authorization, permissions: :read_milestone_issue, boundary_type: :project
      get ":id/milestones/:milestone_id/issues" do
        authorize! :read_milestone, user_project

        milestone_issuables_for(user_project, :issue)
      end

      desc 'List all merge requests for a project milestone' do
        detail 'Lists all merge requests assigned to a specified project milestone.'
        success Entities::MergeRequestBasic
        tags ['milestones']
      end
      params do
        requires :milestone_id, type: Integer, desc: 'The ID of a project milestone'
        use :pagination
      end
      route_setting :authorization, permissions: :read_milestone_merge_request, boundary_type: :project
      get ':id/milestones/:milestone_id/merge_requests' do
        authorize! :read_milestone, user_project

        milestone_issuables_for(user_project, :merge_request)
      end

      desc 'Promote a project milestone to a group milestone' do
        detail 'Promotes a specified project milestone to a group milestone. Only for users with the Planner, ' \
          'Reporter, Developer, Maintainer, or Owner role for the group.'
        tags ['milestones']
      end
      route_setting :authorization, permissions: :promote_milestone, boundary_type: :project
      post ':id/milestones/:milestone_id/promote' do
        authorize! :admin_milestone, user_project
        authorize! :admin_milestone, user_project.group

        milestone = user_project.milestones.find(params[:milestone_id])
        Milestones::PromoteService.new(user_project, current_user).execute(milestone)

        status(200)
      rescue Milestones::PromoteService::PromoteMilestoneError => error
        render_api_error!(error.message, 400)
      end
    end
  end
end

API::ProjectMilestones.prepend_mod_with('API::ProjectMilestones')
