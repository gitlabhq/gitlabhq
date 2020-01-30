# frozen_string_literal: true

module API
  module Entities
    class Member < Grape::Entity
      expose :user, merge: true, using: UserBasic
      expose :access_level
      expose :expires_at
    end
  end
end
