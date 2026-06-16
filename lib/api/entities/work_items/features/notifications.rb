# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      module Features
        class Notifications < Grape::Entity
          expose :subscribed,
            documentation: { type: 'Boolean', example: true } do |widget, options|
            current_user = options[:current_user]
            next false unless current_user

            work_item = widget.work_item
            cache = options[:notifications_subscriptions] || {}
            subscription = cache[work_item.id]
            next subscription.subscribed if subscription

            # Cheap participant cases (author / assignee) are served from preloaded data with no per-item queries, so
            # listing endpoints always get them
            if work_item.author_id == current_user.id ||
                work_item.issue_assignees.any? { |ia| ia.user_id == current_user.id }
              next true
            end

            # Note authors / mentioned users / emoji reactors require participant?, which loads notes + award_emoji per
            # work item. That's bounded for a single work item (show / create / update) but an N+1 source on the listing
            # query, so only the single-item render paths opt in via this flag
            next false unless options[:notifications_allow_participant_fallback]

            work_item.participant?(current_user)
          end
        end
      end
    end
  end
end
