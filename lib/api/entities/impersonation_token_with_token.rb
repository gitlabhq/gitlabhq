# frozen_string_literal: true

module API
  module Entities
    class ImpersonationTokenWithToken < Entities::ImpersonationToken
      expose :token
    end
  end
end
