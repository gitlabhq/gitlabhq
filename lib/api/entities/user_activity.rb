# frozen_string_literal: true

module API
  module Entities
    class UserActivity < Grape::Entity
      expose :username
      expose :last_activity_on
      expose :last_activity_on, as: :last_activity_at # Back-compat
    end
  end
end
