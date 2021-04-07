# frozen_string_literal: true

module Groups
  module Settings
    class ApplicationsController < Groups::ApplicationController
      include OauthApplications

      prepend_before_action :authorize_admin_group!
      before_action :set_application, only: [:show, :edit, :update, :destroy]
      before_action :load_scopes, only: [:index, :create, :edit, :update]

      feature_category :authentication_and_authorization

      def index
        set_index_vars
      end

      def show
      end

      def edit
      end

      def create
        @application = Applications::CreateService.new(current_user, application_params).execute(request)

        if @application.persisted?
          flash[:notice] = I18n.t(:notice, scope: [:doorkeeper, :flash, :applications, :create])

          redirect_to group_settings_application_url(@group, @application)
        else
          set_index_vars
          render :index
        end
      end

      def update
        if @application.update(application_params)
          redirect_to group_settings_application_path(@group, @application), notice: _('Application was successfully updated.')
        else
          render :edit
        end
      end

      def destroy
        @application.destroy
        redirect_to group_settings_applications_url(@group), status: :found, notice: _('Application was successfully destroyed.')
      end

      private

      def set_index_vars
        # TODO: Remove limit(100) and implement pagination
        # https://gitlab.com/gitlab-org/gitlab/-/issues/324187
        @applications = @group.oauth_applications.limit(100)

        # Don't overwrite a value possibly set by `create`
        @application ||= Doorkeeper::Application.new
      end

      def set_application
        @application = @group.oauth_applications.find(params[:id])
      end

      def application_params
        params
          .require(:doorkeeper_application)
          .permit(:name, :redirect_uri, :scopes, :confidential)
          .tap do |params|
            params[:owner] = @group
          end
      end
    end
  end
end
