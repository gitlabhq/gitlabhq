# frozen_string_literal: true

module API
  module Entities
    class PersonalAccessTokenWithLastUsedIps < Entities::PersonalAccessToken
      expose :last_used_ips, documentation: { type: 'array',
                                              example: ['127.0.0.1',
                                                '127.0.0.2',
                                                '127.0.0.3'] } do |personal_access_token|
        personal_access_token.last_used_ips.map(&:ip_address)
      end
    end
  end
end
