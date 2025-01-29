# frozen_string_literal: true

module ResourceAccessTokens
  class CreateService < BaseService
    include Gitlab::Utils::StrongMemoize

    def initialize(current_user, resource, params = {})
      @resource_type = resource.class.name.downcase
      @resource = resource
      @current_user = current_user
      @params = params.dup
    end

    def execute
      return error("User does not have permission to create #{resource_type} access token") unless has_permission_to_create?

      access_level = params[:access_level] || Gitlab::Access::MAINTAINER
      return error("Could not provision owner access to project access token") if do_not_allow_owner_access_level_for_project_bot?(access_level)

      return error("Access level of the token can't be greater the access level of the user who created the token") unless validate_access_level(access_level)

      return error(s_('AccessTokens|Access token limit reached')) if reached_access_token_limit?

      response = create_user

      return error(response.message) if response.error?

      user = response.payload[:user]

      user.update!(external: true) if current_user.external?

      member = create_membership(resource, user, access_level)

      unless member.persisted?
        delete_failed_user(user)
        return error("Could not provision #{Gitlab::Access.human_access(access_level.to_i).downcase} access to the access token. ERROR: #{member.errors.full_messages.to_sentence}")
      end

      token_response = create_personal_access_token(user)

      if token_response.success?
        log_event(token_response.payload[:personal_access_token])
        success(token_response.payload[:personal_access_token])
      else
        delete_failed_user(user)
        error(token_response.message)
      end
    end

    private

    attr_reader :resource_type, :resource

    def reached_access_token_limit?
      false
    end

    def username_and_email_generator
      Gitlab::Utils::UsernameAndEmailGenerator.new(
        username_prefix: "#{resource_type}_#{resource.id}_bot",
        email_domain: "noreply.#{Gitlab.config.gitlab.host}"
      )
    end
    strong_memoize_attr :username_and_email_generator

    def has_permission_to_create?
      %w[project group].include?(resource_type) && can?(current_user, :create_resource_access_tokens, resource)
    end

    def create_user
      # Even project maintainers/owners can create project access tokens, which in turn
      # creates a bot user, and so it becomes necessary to  have `skip_authorization: true`
      # since someone like a project maintainer/owner does not inherently have the ability
      # to create a new user in the system.

      ::Users::AuthorizedCreateService.new(current_user, default_user_params).execute
    end

    def delete_failed_user(user)
      DeleteUserWorker.perform_async(current_user.id, user.id, hard_delete: true, skip_authorization: true, reason_for_deletion: "Access token creation failed")
    end

    def default_user_params
      {
        name: params[:name] || "#{resource.name.to_s.humanize} bot",
        email: username_and_email_generator.email,
        username: username_and_email_generator.username,
        user_type: :project_bot,
        skip_confirmation: true, # Bot users should always have their emails confirmed.
        organization_id: resource.organization_id,
        bot_namespace: bot_namespace
      }
    end

    def create_personal_access_token(user)
      organization_id = resource.organization_id || params[:organization_id]
      PersonalAccessTokens::CreateService.new(
        current_user: user, target_user: user, organization_id: organization_id, params: personal_access_token_params
      ).execute
    end

    def personal_access_token_params
      {
        name: params[:name] || "#{resource_type}_bot",
        impersonation: false,
        scopes: params[:scopes] || default_scopes,
        expires_at: pat_expiration,
        description: params[:description]
      }
    end

    def default_scopes
      Gitlab::Auth.resource_bot_scopes
    end

    def create_membership(resource, user, access_level)
      resource.add_member(user, access_level)
    end

    def pat_expiration
      return params[:expires_at] if params[:expires_at].present?

      if Gitlab::CurrentSettings.require_personal_access_token_expiry?
        return PersonalAccessToken::MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS.days.from_now
      end

      nil
    end

    def bot_namespace
      return resource if resource_type == 'group'

      resource.project_namespace
    end

    def log_event(token)
      ::Gitlab::AppLogger.info "PROJECT ACCESS TOKEN CREATION: created_by: #{current_user.username}, project_id: #{resource.id}, token_user: #{token.user.name}, token_id: #{token.id}"
    end

    def error(message)
      ServiceResponse.error(message: message)
    end

    def success(access_token)
      ServiceResponse.success(payload: { access_token: access_token })
    end

    def validate_access_level(access_level)
      return true if current_user.bot?
      return true if current_user.can?(:owner_access, resource)

      resource.member?(current_user, access_level.to_i)
    end

    def do_not_allow_owner_access_level_for_project_bot?(access_level)
      resource.is_a?(Project) &&
        access_level.to_i == Gitlab::Access::OWNER &&
        !current_user.can?(:manage_owners, resource)
    end
  end
end

ResourceAccessTokens::CreateService.prepend_mod_with('ResourceAccessTokens::CreateService')
