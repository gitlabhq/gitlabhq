# frozen_string_literal: true

module API
  module Entities
    class ImpersonationTokenWithToken < Entities::PersonalAccessTokenWithToken
      expose :impersonation
    end
  end
end
