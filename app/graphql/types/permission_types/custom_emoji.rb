# frozen_string_literal: true

module Types
  module PermissionTypes
    class CustomEmoji < BasePermissionType
      graphql_name 'CustomEmojiPermissions'

      abilities :create_custom_emoji, :read_custom_emoji, :delete_custom_emoji
    end
  end
end
