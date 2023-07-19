# frozen_string_literal: true

module Gitlab
  module HookData
    class EmojiBuilder < BaseBuilder
      SAFE_HOOK_ATTRIBUTES = %i[
        user_id
        created_at
        id
        name
        awardable_type
        awardable_id
        updated_at
      ].freeze

      alias_method :award_emoji, :object

      def build
        award_emoji
          .attributes
          .with_indifferent_access
          .slice(*SAFE_HOOK_ATTRIBUTES)
      end
    end
  end
end
