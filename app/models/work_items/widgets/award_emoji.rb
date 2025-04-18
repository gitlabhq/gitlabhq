# frozen_string_literal: true

module WorkItems
  module Widgets
    class AwardEmoji < Base
      delegate :award_emoji, :downvotes, :upvotes, to: :work_item

      def new_custom_emoji_path(user)
        namespace = work_item&.project&.namespace || work_item&.namespace

        return unless namespace

        return unless user&.can?(:create_custom_emoji, namespace)

        Gitlab::Routing.url_helpers.new_group_custom_emoji_path(namespace)
      end
    end
  end
end
