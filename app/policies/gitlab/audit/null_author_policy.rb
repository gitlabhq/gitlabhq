# frozen_string_literal: true

module Gitlab
  module Audit
    class NullAuthorPolicy < BasePolicy
      rule { ~restricted_public_level }.enable :read_user
      rule { ~anonymous }.enable :read_user
    end
  end
end
