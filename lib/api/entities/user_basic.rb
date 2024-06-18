# frozen_string_literal: true

module API
  module Entities
    class UserBasic < UserSafe
      expose :state, documentation: { type: 'string', example: 'active' }
      expose :access_locked?, as: :locked, documentation: { type: 'boolean' }

      expose :avatar_url, documentation: { type: 'string', example: 'https://gravatar.com/avatar/1' } do |user, options|
        user.avatar_url(only_path: false)
      end

      expose(
        :avatar_path,
        documentation: {
          type: 'string',
          example: '/user/avatar/28/The-Big-Lebowski-400-400.png'
        },
        if: ->(user, options) { options.fetch(:only_path, false) && user.avatar_path }
      )

      expose :custom_attributes, using: 'API::Entities::CustomAttribute', if: :with_custom_attributes,
        documentation: { is_array: true }

      expose :web_url, documentation: { type: 'string', example: 'https://gitlab.example.com/root' } do |user, options|
        Gitlab::Routing.url_helpers.user_url(user)
      end
    end
  end
end

API::Entities::UserBasic.prepend_mod_with('API::Entities::UserBasic')
