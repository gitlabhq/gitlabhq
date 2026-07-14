# frozen_string_literal: true

module API
  module Entities
    class PersonalAccessTokenWithToken < Entities::PersonalAccessToken
      expose :token
      expose :granular_scopes, using: ::API::Entities::PersonalAccessTokenGranularScope,
        if: ->(token, options) { token.granular? && options[:with_granular_scopes] },
        documentation: { is_array: true }
    end
  end
end
