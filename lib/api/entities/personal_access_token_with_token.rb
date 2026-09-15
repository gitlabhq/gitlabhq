# frozen_string_literal: true

module API
  module Entities
    class PersonalAccessTokenWithToken < Entities::PersonalAccessToken
      expose :token
    end
  end
end
