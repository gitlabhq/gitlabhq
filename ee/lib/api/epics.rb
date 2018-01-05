module API
  class Epics < Grape::API
    before do
      authenticate!
      authorize_epics_feature!
    end

    helpers do
      def authorize_epics_feature!
        forbidden! unless user_group.feature_available?(:epics)
      end

      def authorize_can_read!
        authorize!(:read_epic, epic)
      end

      def authorize_can_admin!
        authorize!(:admin_epic, epic)
      end

      def authorize_can_create!
        authorize!(:admin_epic, user_group)
      end

      def authorize_can_destroy!
        authorize!(:destroy_epic, epic)
      end

      def epic
        @epic ||= user_group.epics.find_by(iid: params[:epic_iid])
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end

    resource :groups, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc 'Get epics for the group' do
        success Entities::Epic
      end
      get ':id/-/epics' do
        present user_group.epics, with: Entities::Epic
      end

      desc 'Get details of an epic' do
        success Entities::Epic
      end
      params do
        requires :epic_iid, type: Integer, desc: 'The internal ID of an epic'
      end
      get ':id/-/epics/:epic_iid' do
        authorize_can_read!

        present epic, with: Entities::Epic
      end

      desc 'Create a new epic' do
        success Entities::Epic
      end
      params do
        requires :title, type: String, desc: 'The title of an epic'
        optional :description, type: String, desc: 'The description of an epic'
        optional :start_date, type: String, desc: 'The start date of an epic'
        optional :end_date, type: String, desc: 'The end date of an epic'
      end
      post ':id/-/epics' do
        authorize_can_create!

        epic = ::Epics::CreateService.new(user_group, current_user, declared_params(include_missing: false)).execute
        if epic.valid?
          present epic, with: Entities::Epic
        else
          render_validation_error!(epic)
        end
      end

      desc 'Update an epic' do
        success Entities::Epic
      end
      params do
        requires :epic_iid, type: Integer, desc: 'The internal ID of an epic'
        optional :title, type: String, desc: 'The title of an epic'
        optional :description, type: String, desc: 'The description of an epic'
        optional :start_date, type: String, desc: 'The start date of an epic'
        optional :end_date, type: String, desc: 'The end date of an epic'
        at_least_one_of :title, :description, :start_date, :end_date
      end
      put ':id/-/epics/:epic_iid' do
        authorize_can_admin!
        update_params = declared_params(include_missing: false)
        update_params.delete(:epic_iid)

        result = ::Epics::UpdateService.new(nil, current_user, update_params).execute(epic)

        if result.valid?
          present result, with: Entities::Epic
        else
          render_validation_error!(result)
        end
      end

      desc 'Destroy an epic' do
        success Entities::Epic
      end
      params do
        requires :epic_iid, type: Integer, desc: 'The internal ID of an epic'
      end
      delete ':id/-/epics/:epic_iid' do
        authorize_can_destroy!

        Issuable::DestroyService.new(nil, current_user).execute(epic)
      end
    end
  end
end
