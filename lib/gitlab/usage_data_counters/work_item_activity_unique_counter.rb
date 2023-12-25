# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module WorkItemActivityUniqueCounter
      WORK_ITEM_CREATED = 'users_creating_work_items'
      WORK_ITEM_TITLE_CHANGED = 'users_updating_work_item_title'
      WORK_ITEM_DATE_CHANGED = 'users_updating_work_item_dates'
      WORK_ITEM_LABELS_CHANGED = 'users_updating_work_item_labels'
      WORK_ITEM_MILESTONE_CHANGED = 'users_updating_work_item_milestone'
      WORK_ITEM_TODO_MARKED = 'users_updating_work_item_todo'

      class << self
        def track_work_item_created_action(author:)
          track_unique_action(WORK_ITEM_CREATED, author)
        end

        def track_work_item_title_changed_action(author:)
          track_unique_action(WORK_ITEM_TITLE_CHANGED, author)
        end

        def track_work_item_date_changed_action(author:)
          track_unique_action(WORK_ITEM_DATE_CHANGED, author)
        end

        def track_work_item_labels_changed_action(author:)
          track_unique_action(WORK_ITEM_LABELS_CHANGED, author)
        end

        def track_work_item_milestone_changed_action(author:)
          track_unique_action(WORK_ITEM_MILESTONE_CHANGED, author)
        end

        def track_work_item_mark_todo_action(author:)
          track_unique_action(WORK_ITEM_TODO_MARKED, author)
        end

        private

        def track_unique_action(action, author)
          return unless author

          Gitlab::UsageDataCounters::HLLRedisCounter.track_event(action, values: author.id)
        end
      end
    end
  end
end

# rubocop:disable Layout/LineLength
Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter.prepend_mod_with('Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter')
# rubocop:enable Layout/LineLength
