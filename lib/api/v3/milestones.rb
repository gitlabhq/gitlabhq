module API
  module V3
    class Milestones < Grape::API
      include PaginationParams

      before { authenticate! }

      helpers do
        def filter_milestones_state(milestones, state)
          case state
          when 'active' then milestones.active
          when 'closed' then milestones.closed
          else milestones
          end
        end
      end

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects, requirements: { id: %r{[^/]+} } do
        desc 'Get a list of project milestones' do
          success ::API::Entities::Milestone
        end
        params do
          optional :state, type: String, values: %w[active closed all], default: 'all',
                           desc: 'Return "active", "closed", or "all" milestones'
          optional :iid, type: Array[Integer], desc: 'The IID of the milestone'
          use :pagination
        end
        get ":id/milestones" do
          authorize! :read_milestone, user_project

          milestones = user_project.milestones
          milestones = filter_milestones_state(milestones, params[:state])
          milestones = filter_by_iid(milestones, params[:iid]) if params[:iid].present?
          milestones = milestones.order_id_desc

          present paginate(milestones), with: ::API::Entities::Milestone
        end

        desc 'Get all issues for a single project milestone' do
          success ::API::V3::Entities::Issue
        end
        params do
          requires :milestone_id, type: Integer, desc: 'The ID of a project milestone'
          use :pagination
        end
        get ':id/milestones/:milestone_id/issues' do
          authorize! :read_milestone, user_project

          milestone = user_project.milestones.find(params[:milestone_id])

          finder_params = {
            project_id: user_project.id,
            milestone_title: milestone.title
          }

          issues = IssuesFinder.new(current_user, finder_params).execute
          present paginate(issues), with: ::API::V3::Entities::Issue, current_user: current_user, project: user_project
        end
      end
    end
  end
end
