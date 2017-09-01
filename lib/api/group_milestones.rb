module API
  class GroupMilestones < Grape::API
    include MilestoneResponses
    include PaginationParams

    before do
      authenticate!
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc 'Get a list of group milestones' do
        success Entities::Milestone
      end
      params do
        use :list_params
      end
      get ":id/milestones" do
        list_milestones_for(user_group)
      end

      desc 'Get a single group milestone' do
        success Entities::Milestone
      end
      params do
        requires :milestone_id, type: Integer, desc: 'The ID of a group milestone'
      end
      get ":id/milestones/:milestone_id" do
        authorize! :read_group, user_group

        get_milestone_for(user_group)
      end

      desc 'Create a new group milestone' do
        success Entities::Milestone
      end
      params do
        requires :title, type: String, desc: 'The title of the milestone'
        use :optional_params
      end
      post ":id/milestones" do
        authorize! :admin_milestones, user_group

        create_milestone_for(user_group)
      end

      desc 'Update an existing group milestone' do
        success Entities::Milestone
      end
      params do
        use :update_params
      end
      put ":id/milestones/:milestone_id" do
        authorize! :admin_milestones, user_group

        update_milestone_for(user_group)
      end

      desc 'Get all issues for a single group milestone' do
        success Entities::IssueBasic
      end
      params do
        requires :milestone_id, type: Integer, desc: 'The ID of a group milestone'
        use :pagination
      end
      get ":id/milestones/:milestone_id/issues" do
        milestone_issuables_for(user_group, :issue)
      end

      desc 'Get all merge requests for a single group milestone' do
        detail 'This feature was introduced in GitLab 9.'
        success Entities::MergeRequestBasic
      end
      params do
        requires :milestone_id, type: Integer, desc: 'The ID of a group milestone'
        use :pagination
      end
      get ':id/milestones/:milestone_id/merge_requests' do
        milestone_issuables_for(user_group, :merge_request)
      end
    end
  end
end
