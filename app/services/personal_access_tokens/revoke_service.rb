# frozen_string_literal: true

module PersonalAccessTokens
  class RevokeService < BaseService
    attr_reader :token, :current_user, :group, :source

    VALID_SOURCES = %i[self secret_detection group_token_revocation_service api_admin_token].freeze

    def initialize(current_user = nil, token: nil, group: nil, source: nil)
      @current_user = current_user
      @token = token
      @group = group
      @source = source

      @source = :self if @current_user && !@source

      raise ArgumentError unless VALID_SOURCES.include?(@source)
    end

    def execute
      return ServiceResponse.error(message: 'Not permitted to revoke') unless revocation_permitted?

      if token.revoke!
        log_event
        notification_service.access_token_revoked(token.user, token.name, source)
        ServiceResponse.success(message: success_message)
      else
        ServiceResponse.error(message: error_message)
      end
    end

    private

    def error_message
      _('Could not revoke personal access token "%{personal_access_token_name}".') % { personal_access_token_name: token.name }
    end

    def success_message
      _('Revoked personal access token "%{personal_access_token_name}".') % { personal_access_token_name: token.name }
    end

    def revocation_permitted?
      case source
      when :self
        Ability.allowed?(current_user, :revoke_token, token)
      when :secret_detection, :group_token_revocation_service, :api_admin_token
        true
      else
        false
      end
    end

    def log_event
      Gitlab::AppLogger.info(
        class: self.class.name,
        message: "PAT Revoked",
        revoked_by: revoked_by,
        revoked_for: token.user.username,
        token_id: token.id)
    end

    def revoked_by
      return current_user&.username if source == :self

      source
    end
  end
end

PersonalAccessTokens::RevokeService.prepend_mod_with('PersonalAccessTokens::RevokeService')
