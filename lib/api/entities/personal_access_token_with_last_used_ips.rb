# frozen_string_literal: true

module API
  module Entities
    class PersonalAccessTokenWithLastUsedIps < Entities::PersonalAccessToken
      expose :last_used_ips,
        if: ->(token, _) { ::Feature.enabled?(:expose_last_used_ips_for_access_tokens, token.user) },
        documentation: {
          type: 'String',
          desc: 'The five most recent unique IP addresses that have authenticated with this ' \
            'token. When the limit is reached, the oldest IP address is removed. The list updates ' \
            'once per minute per token.',
          is_array: true,
          example: ['127.0.0.1', '127.0.0.2', '127.0.0.3']
        } do |personal_access_token|
        personal_access_token.last_used_ips.map(&:ip_address)
      end

      expose :granular_scopes, using: ::API::Entities::PersonalAccessTokenGranularScope,
        if: ->(token, options) { token.granular? && options[:with_granular_scopes] },
        documentation: { is_array: true }
    end
  end
end
