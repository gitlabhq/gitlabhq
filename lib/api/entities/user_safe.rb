# frozen_string_literal: true

module API
  module Entities
    class UserSafe < Grape::Entity
      include RequestAwareEntity

      expose :id, documentation: { type: 'Integer', example: 1 }
      expose :username, documentation: { type: 'String', example: 'admin' }
      expose :public_email, documentation: { type: 'String', example: 'john@example.com' }
      expose :name, documentation: { type: 'String', example: 'Administrator' } do |user|
        current_user = request.respond_to?(:current_user) ? request.current_user : options.fetch(:current_user, nil)

        user.redacted_name(current_user)
      end
    end
  end
end
