# frozen_string_literal: true

module API
  module Entities
    class PersonalAccessTokenWithDetails < Entities::PersonalAccessToken
      expose :expired?, as: :expired
      expose :expires_soon?, as: :expires_soon
      expose :revoke_path do |token|
        Gitlab::Routing.url_helpers.revoke_profile_personal_access_token_path(token)
      end
    end
  end
end
