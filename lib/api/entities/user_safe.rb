# frozen_string_literal: true

module API
  module Entities
    class UserSafe < Grape::Entity
      include RequestAwareEntity

      expose :id, :username
      expose :name do |user|
        current_user = request.respond_to?(:current_user) ? request.current_user : options.fetch(:current_user, nil)

        user.redacted_name(current_user)
      end
    end
  end
end
