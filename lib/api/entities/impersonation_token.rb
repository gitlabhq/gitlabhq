# frozen_string_literal: true

module API
  module Entities
    class ImpersonationToken < Entities::PersonalAccessToken
      expose :impersonation
    end
  end
end
