# frozen_string_literal: true

module PersonalAccessTokens
  class RevokeService
    attr_reader :token, :current_user, :group

    def initialize(current_user = nil, token: nil, group: nil )
      @current_user = current_user
      @token = token
      @group = group
    end

    def execute
      return ServiceResponse.error(message: 'Not permitted to revoke') unless revocation_permitted?

      if token.revoke!
        log_event
        ServiceResponse.success(message: success_message)
      else
        ServiceResponse.error(message: error_message)
      end
    end

    private

    def error_message
      _("Could not revoke personal access token %{personal_access_token_name}.") % { personal_access_token_name: token.name }
    end

    def success_message
      _("Revoked personal access token %{personal_access_token_name}!") % { personal_access_token_name: token.name }
    end

    def revocation_permitted?
      Ability.allowed?(current_user, :revoke_token, token)
    end

    def log_event
      Gitlab::AppLogger.info("PAT REVOCATION: revoked_by: '#{current_user.username}', revoked_for: '#{token.user.username}', token_id: '#{token.id}'")
    end
  end
end

PersonalAccessTokens::RevokeService.prepend_mod_with('PersonalAccessTokens::RevokeService')
