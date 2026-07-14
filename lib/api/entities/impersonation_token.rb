# frozen_string_literal: true

module API
  module Entities
    class ImpersonationToken < Entities::PersonalAccessTokenWithLastUsedIps
      expose :impersonation
    end
  end
end
