# frozen_string_literal: true

module API
  module Entities
    class UserBasic < UserSafe
      expose :state

      expose :avatar_url do |user, options|
        user.avatar_url(only_path: false)
      end

      expose :avatar_path, if: ->(user, options) { options.fetch(:only_path, false) && user.avatar_path }
      expose :custom_attributes, using: 'API::Entities::CustomAttribute', if: :with_custom_attributes

      expose :web_url do |user, options|
        Gitlab::Routing.url_helpers.user_url(user)
      end
    end
  end
end

API::Entities::UserBasic.prepend_mod_with('API::Entities::UserBasic')
