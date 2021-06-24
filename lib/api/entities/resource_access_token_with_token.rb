# frozen_string_literal: true

module API
  module Entities
    class ResourceAccessTokenWithToken < Entities::ResourceAccessToken
      expose :token
    end
  end
end
