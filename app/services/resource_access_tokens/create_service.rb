# frozen_string_literal: true

module ResourceAccessTokens
  class CreateService < BaseService
    def initialize(current_user, resource, params = {})
      @resource_type = resource.class.name.downcase
      @resource = resource
      @current_user = current_user
      @params = params.dup
    end

    def execute
      return error("User does not have permission to create #{resource_type} access token") unless has_permission_to_create?

      user = create_user

      return error(user.errors.full_messages.to_sentence) unless user.persisted?

      access_level = params[:access_level] || Gitlab::Access::MAINTAINER
      member = create_membership(resource, user, access_level)

      unless member.persisted?
        delete_failed_user(user)
        return error("Could not provision #{Gitlab::Access.human_access(access_level).downcase} access to project access token")
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

    def has_permission_to_create?
      %w(project group).include?(resource_type) && can?(current_user, :create_resource_access_tokens, resource)
    end

    def create_user
      # Even project maintainers can create project access tokens, which in turn
      # creates a bot user, and so it becomes necessary to  have `skip_authorization: true`
      # since someone like a project maintainer does not inherently have the ability
      # to create a new user in the system.

      ::Users::AuthorizedCreateService.new(current_user, default_user_params).execute
    end

    def delete_failed_user(user)
      DeleteUserWorker.perform_async(current_user.id, user.id, hard_delete: true, skip_authorization: true)
    end

    def default_user_params
      {
        name: params[:name] || "#{resource.name.to_s.humanize} bot",
        email: generate_email,
        username: generate_username,
        user_type: "#{resource_type}_bot".to_sym,
        skip_confirmation: true # Bot users should always have their emails confirmed.
      }
    end

    def generate_username
      base_username = "#{resource_type}_#{resource.id}_bot"

      uniquify.string(base_username) { |s| User.find_by_username(s) }
    end

    def generate_email
      email_pattern = "#{resource_type}#{resource.id}_bot%s@example.com"

      uniquify.string(-> (n) { Kernel.sprintf(email_pattern, n) }) do |s|
        User.find_by_email(s)
      end
    end

    def uniquify
      Uniquify.new
    end

    def create_personal_access_token(user)
      PersonalAccessTokens::CreateService.new(
        current_user: user, target_user: user, params: personal_access_token_params
      ).execute
    end

    def personal_access_token_params
      {
        name: params[:name] || "#{resource_type}_bot",
        impersonation: false,
        scopes: params[:scopes] || default_scopes,
        expires_at: params[:expires_at] || nil
      }
    end

    def default_scopes
      Gitlab::Auth.resource_bot_scopes
    end

    def create_membership(resource, user, access_level)
      resource.add_user(user, access_level, expires_at: params[:expires_at])
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
  end
end

ResourceAccessTokens::CreateService.prepend_mod_with('ResourceAccessTokens::CreateService')
