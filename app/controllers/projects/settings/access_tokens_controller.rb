# frozen_string_literal: true

module Projects
  module Settings
    class AccessTokensController < Projects::ApplicationController
      include ProjectsHelper

      layout 'project_settings'
      before_action -> { check_permission(:read_resource_access_tokens) }, only: [:index]
      before_action -> { check_permission(:destroy_resource_access_tokens) }, only: [:revoke]
      before_action -> { check_permission(:create_resource_access_tokens) }, only: [:create]

      feature_category :authentication_and_authorization

      def index
        @project_access_token = PersonalAccessToken.new
        set_index_vars
      end

      def create
        token_response = ResourceAccessTokens::CreateService.new(current_user, @project, create_params).execute

        if token_response.success?
          @project_access_token = token_response.payload[:access_token]
          PersonalAccessToken.redis_store!(key_identity, @project_access_token.token)

          redirect_to namespace_project_settings_access_tokens_path, notice: _("Your new project access token has been created.")
        else
          redirect_to namespace_project_settings_access_tokens_path, alert: _("Failed to create new project access token: %{token_response_message}") % { token_response_message: token_response.message }
        end
      end

      def revoke
        @project_access_token = finder.find(params[:id])
        revoked_response = ResourceAccessTokens::RevokeService.new(current_user, @project, @project_access_token).execute

        if revoked_response.success?
          flash[:notice] = _("Revoked project access token %{project_access_token_name}!") % { project_access_token_name: @project_access_token.name }
        else
          flash[:alert] = _("Could not revoke project access token %{project_access_token_name}.") % { project_access_token_name: @project_access_token.name }
        end

        redirect_to namespace_project_settings_access_tokens_path
      end

      private

      def check_permission(action)
        render_404 unless can?(current_user, action, @project)
      end

      def create_params
        params.require(:project_access_token).permit(:name, :expires_at, :access_level, scopes: [])
      end

      def set_index_vars
        # Loading project members so that we can fetch access level of the bot
        # user in the project without multiple queries.
        @project.project_members.load

        @scopes = Gitlab::Auth.resource_bot_scopes
        @active_project_access_tokens = finder(state: 'active').execute.preload_users
        @inactive_project_access_tokens = finder(state: 'inactive', sort: 'expires_at_asc').execute.preload_users
        @new_project_access_token = PersonalAccessToken.redis_getdel(key_identity)
      end

      def finder(options = {})
        PersonalAccessTokensFinder.new({ user: bot_users, impersonation: false }.merge(options))
      end

      def bot_users
        @project.bots
      end

      def key_identity
        "#{current_user.id}:#{@project.id}"
      end
    end
  end
end
