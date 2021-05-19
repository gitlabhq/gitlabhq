# frozen_string_literal: true

module API
  module Entities
    class Member < Grape::Entity
      expose :user, merge: true, using: UserBasic
      expose :access_level
      expose :created_at
      expose :expires_at
    end
  end
end

API::Entities::Member.prepend_mod_with('API::Entities::Member', with_descendants: true)
