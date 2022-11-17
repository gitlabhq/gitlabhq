# frozen_string_literal: true

module API
  module Entities
    class UserSafe < Grape::Entity
      include RequestAwareEntity

      expose :id, documentation: { type: 'integer', example: 1 }
      expose :username, documentation: { type: 'string', example: 'admin' }
      expose :name, documentation: { type: 'string', example: 'Administrator' } do |user|
        current_user = request.respond_to?(:current_user) ? request.current_user : options.fetch(:current_user, nil)

        user.redacted_name(current_user)
      end
    end
  end
end
