# frozen_string_literal: true

module API
  module Entities
    class AccessRequester < Grape::Entity
      expose :user, merge: true, using: UserBasic
      expose :requested_at
    end
  end
end
