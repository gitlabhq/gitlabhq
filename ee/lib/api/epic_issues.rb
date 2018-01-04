module API
  class EpicIssues < Grape::API
    before do
      authenticate!
      authorize_epics!
    end

    helpers do
      def authorize_epics!
        forbidden! unless user_group.feature_available?(:epics)
      end

      def authorize_can_admin!
        authorize!(:admin_epic, epic)
      end

      def epic
        @epic ||= user_group.epics.find_by(iid: params[:epic_iid])
      end

      def link
        @link ||= epic.epic_issues.find(params[:epic_issue_id])
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
        requires :epic_issue_id, type: Integer, desc: 'The id of the epic issue association to update'
        optional :move_before_id, type: Integer, desc: 'The id of the epic issue association that should be positioned before the actual issue'
        optional :move_after_id, type: Integer, desc: 'The id of the epic issue association that should be positioned after the actual issue'
      end
      put ':id/-/epics/:epic_iid/issues/:epic_issue_id' do
        authorize_can_admin!

        update_params = {
          move_before_id: params[:move_before_id],
          move_after_id: params[:move_after_id],
        }

        result = ::EpicIssues::UpdateService.new(link, current_user, update_params).execute

        # For now we return empty body
        # The issues list in the correct order in body will be returned as part of #4250
        render_api_error!({ error: "Issue could not be moved!" }, 400) unless result
      end
    end
  end
end
