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
      return error("Failed to find bot user") unless find_member

      PersonalAccessToken.transaction do
        access_token.revoke!

        raise RevokeAccessTokenError, "Failed to remove #{bot_user.name} member from: #{resource.name}" unless remove_member

        raise RevokeAccessTokenError, "Migration to ghost user failed" unless migrate_to_ghost_user
      end

      success("Revoked access token: #{access_token.name}")
    rescue ActiveRecord::ActiveRecordError, RevokeAccessTokenError => error
      log_error("Failed to revoke access token for #{bot_user.name}: #{error.message}")
      error(error.message)
    end

    private

    attr_reader :current_user, :access_token, :bot_user, :resource

    def remove_member
      ::Members::DestroyService.new(current_user).execute(find_member)
    end

    def migrate_to_ghost_user
      ::Users::MigrateToGhostUserService.new(bot_user).execute
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
