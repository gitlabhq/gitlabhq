# frozen_string_literal: true

module WorkItems
  module Widgets
    class AwardEmoji < Base
      delegate :award_emoji, :downvotes, :upvotes, to: :work_item
    end
  end
end
