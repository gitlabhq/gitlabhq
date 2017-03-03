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
      resource :projects do
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

          present paginate(milestones), with: ::API::Entities::Milestone
        end
      end
    end
  end
end
