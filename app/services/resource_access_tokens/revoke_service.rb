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
      return error("#{current_user.name} cannot delete #{bot_user.name}") unless can_destroy_bot_member?
      return error("Failed to find bot user") unless find_member

      access_token.revoke!

      destroy_bot_user

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

    def can_destroy_bot_member?
      if resource.is_a?(Project)
        can?(current_user, :admin_project_member, @resource)
      elsif resource.is_a?(Group)
        can?(current_user, :admin_group_member, @resource)
      else
        false
      end
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

    def error(message)
      ServiceResponse.error(message: message)
    end

    def success(message)
      ServiceResponse.success(message: message)
    end
  end
end
