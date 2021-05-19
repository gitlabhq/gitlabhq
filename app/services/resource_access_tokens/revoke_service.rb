# frozen_string_literal: true

module ResourceAccessTokens
  class RevokeService < BaseService
    include Gitlab::Utils::StrongMemoize

    RevokeAccessTokenError = Class.new(RuntimeError)

    def initialize(current_user, resource, access_token)
      @current_user = current_user
      @access_token = access_token
      @bot_user = access_token.user
      @resource = resource
    end

    def execute
      return error("#{current_user.name} cannot delete #{bot_user.name}") unless can_destroy_token?
      return error("Failed to find bot user") unless find_member

      access_token.revoke!

      destroy_bot_user

      log_event

      success("Access token #{access_token.name} has been revoked and the bot user has been scheduled for deletion.")
    rescue StandardError => error
      log_error("Failed to revoke access token for #{bot_user.name}: #{error.message}")
      error(error.message)
    end

    private

    attr_reader :current_user, :access_token, :bot_user, :resource

    def destroy_bot_user
      DeleteUserWorker.perform_async(current_user.id, bot_user.id, skip_authorization: true)
    end

    def can_destroy_token?
      %w(project group).include?(resource.class.name.downcase) && can?(current_user, :destroy_resource_access_tokens, resource)
    end

    def find_member
      strong_memoize(:member) do
        if resource.is_a?(Project)
          resource.project_member(bot_user)
        elsif resource.is_a?(Group)
          resource.group_member(bot_user)
        else
          false
        end
      end
    end

    def log_event
      ::Gitlab::AppLogger.info "PROJECT ACCESS TOKEN REVOCATION: revoked_by: #{current_user.username}, project_id: #{resource.id}, token_user: #{access_token.user.name}, token_id: #{access_token.id}"
    end

    def error(message)
      ServiceResponse.error(message: message)
    end

    def success(message)
      ServiceResponse.success(message: message)
    end
  end
end

ResourceAccessTokens::RevokeService.prepend_mod_with('ResourceAccessTokens::RevokeService')
