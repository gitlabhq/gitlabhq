# frozen_string_literal: true

module Mutations
  module CustomEmoji
    class Create < BaseMutation
      include Mutations::ResolvesGroup

      graphql_name 'CreateCustomEmoji'

      authorize :create_custom_emoji

      field :custom_emoji,
            Types::CustomEmojiType,
            null: true,
            description: 'The new custom emoji.'

      argument :group_path, GraphQL::ID_TYPE,
               required: true,
               description: 'Namespace full path the emoji is associated with.'

      argument :name, GraphQL::STRING_TYPE,
               required: true,
               description: 'Name of the emoji.'

      argument :url, GraphQL::STRING_TYPE,
               required: true,
               as: :file,
               description: 'Location of the emoji file.'

      def resolve(group_path:, **args)
        group = authorized_find!(group_path: group_path)
        # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/37911#note_444682238
        args[:external] = true
        args[:creator] = current_user

        custom_emoji = group.custom_emoji.create(args)

        {
          custom_emoji: custom_emoji.valid? ? custom_emoji : nil,
          errors: errors_on_object(custom_emoji)
        }
      end

      private

      def find_object(group_path:)
        resolve_group(full_path: group_path)
      end
    end
  end
end
