module API
  class EpicIssues < Grape::API
    before do
      authenticate!
      check_epics!
    end

    helpers do
      def check_epics!
        forbidden! unless ::License.feature_available?(:epics) # TODO: check for group feature instead
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end

    resource :groups, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc 'Update epic issue association' do
      end
      params do
        requires :epic_iid, type: Integer, desc: 'The iid of the epic'
        requires :epic_issue_id, type: Integer, desc: 'The id of the epic issue association'
        requires :position, type: Integer, desc: 'The new position of the issue in the epic (index starting with 0)'
      end
      put ':id/-/epics/:epic_iid/issues/:epic_issue_id' do
        epic = user_group.epics.find_by(iid: params[:epic_iid])
        authorize!(:admin_epic, epic)

        link = EpicIssue.find(params[:epic_issue_id])
        forbidden! if link.epic != epic

        result = ::EpicIssues::UpdateService
          .new(link, current_user, { position: params[:position].to_i }).execute

        render_api_error!({ error: "Issue could not be moved!" }, 400) unless result
      end
    end
  end
end
