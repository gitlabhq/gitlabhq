# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes
      class AwardEmojiType < BaseObject
        graphql_name 'WorkItemWidgetAwardEmoji'
        description 'Represents the emoji reactions widget'

        implements ::Types::WorkItems::WidgetInterface

        field :award_emoji,
          ::Types::AwardEmojis::AwardEmojiType.connection_type,
          null: true,
          description: 'Emoji reactions on the work item.'
        field :downvotes,
          GraphQL::Types::Int,
          null: false,
          description: 'Number of downvotes the work item has received.'
        field :new_custom_emoji_path,
          GraphQL::Types::String,
          null: true,
          description: 'Path to create a new custom emoji.'
        field :upvotes,
          GraphQL::Types::Int,
          null: false,
          description: 'Number of upvotes the work item has received.'

        def downvotes
          BatchLoaders::AwardEmojiVotesBatchLoader
            .load_downvotes(object.work_item, awardable_class: 'Issue')
        end

        def upvotes
          BatchLoaders::AwardEmojiVotesBatchLoader
            .load_upvotes(object.work_item, awardable_class: 'Issue')
        end

        def new_custom_emoji_path
          return unless context[:current_user]&.can?(:create_custom_emoji, object.work_item.project.namespace)

          ::Gitlab::Routing.url_helpers.new_group_custom_emoji_path(object.work_item.project.namespace)
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end

Types::WorkItems::Widgets::AwardEmojiType.prepend_mod
