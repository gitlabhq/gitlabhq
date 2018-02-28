module API
  class ProjectMilestones < Grape::API
    include PaginationParams
    include MilestoneResponses

    before do
      authenticate!
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc 'Get a list of project milestones' do
        success Entities::Milestone
      end
      params do
        use :list_params
      end
      get ":id/milestones" do
        authorize! :read_milestone, user_project

        list_milestones_for(user_project)
      end

      desc 'Get a single project milestone' do
        success Entities::Milestone
      end
      params do
        requires :milestone_id, type: Integer, desc: 'The ID of a project milestone'
      end
      get ":id/milestones/:milestone_id" do
        authorize! :read_milestone, user_project

        get_milestone_for(user_project)
      end

      desc 'Create a new project milestone' do
        success Entities::Milestone
      end
      params do
        requires :title, type: String, desc: 'The title of the milestone'
        use :optional_params
      end
      post ":id/milestones" do
        authorize! :admin_milestone, user_project

        create_milestone_for(user_project)
      end

      desc 'Update an existing project milestone' do
        success Entities::Milestone
      end
      params do
        use :update_params
      end
      put ":id/milestones/:milestone_id" do
        authorize! :admin_milestone, user_project

        update_milestone_for(user_project)
      end

      desc 'Remove a project milestone'
      delete ":id/milestones/:milestone_id" do
        authorize! :admin_milestone, user_project

        user_project.milestones.find(params[:milestone_id]).destroy

        status(204)
      end

      desc 'Get all issues for a single project milestone' do
        success Entities::IssueBasic
      end
      params do
        requires :milestone_id, type: Integer, desc: 'The ID of a project milestone'
        use :pagination
      end
      get ":id/milestones/:milestone_id/issues" do
        authorize! :read_milestone, user_project

        milestone_issuables_for(user_project, :issue)
      end

      desc 'Get all merge requests for a single project milestone' do
        detail 'This feature was introduced in GitLab 9.'
        success Entities::MergeRequestBasic
      end
      params do
        requires :milestone_id, type: Integer, desc: 'The ID of a project milestone'
        use :pagination
      end
      get ':id/milestones/:milestone_id/merge_requests' do
        authorize! :read_milestone, user_project

        milestone_issuables_for(user_project, :merge_request)
      end
    end
  end
end
