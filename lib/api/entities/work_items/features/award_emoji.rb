# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      module Features
        class AwardEmoji < Grape::Entity
          expose :upvotes, documentation: { type: 'Integer', example: 5 } do |widget, options|
            options.dig(:award_emoji_counts, widget.work_item.id, :up) || 0
          end

          expose :downvotes, documentation: { type: 'Integer', example: 1 } do |widget, options|
            options.dig(:award_emoji_counts, widget.work_item.id, :down) || 0
          end

          expose :new_custom_emoji_path,
            documentation: { type: 'String', example: '/groups/gitlab-org/-/custom_emoji/new' },
            expose_nil: true do |widget, options|
            widget.new_custom_emoji_path(options[:current_user])
          end
        end
      end
    end
  end
end
