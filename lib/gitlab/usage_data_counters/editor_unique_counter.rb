# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module EditorUniqueCounter
      EDIT_BY_SNIPPET_EDITOR = 'g_edit_by_snippet_ide'
      EDIT_BY_SFE = 'g_edit_by_sfe'
      EDIT_BY_WEB_IDE = 'g_edit_by_web_ide'
      EDIT_CATEGORY = 'ide_edit'
      EDIT_BY_LIVE_PREVIEW = 'g_edit_by_live_preview'

      class << self
        def track_web_ide_edit_action(author:, time: Time.zone.now, project:)
          track_unique_action(EDIT_BY_WEB_IDE, author, time, project)
        end

        def count_web_ide_edit_actions(date_from:, date_to:)
          count_unique(EDIT_BY_WEB_IDE, date_from, date_to)
        end

        def track_sfe_edit_action(author:, time: Time.zone.now, project:)
          track_unique_action(EDIT_BY_SFE, author, time, project)
        end

        def count_sfe_edit_actions(date_from:, date_to:)
          count_unique(EDIT_BY_SFE, date_from, date_to)
        end

        def track_snippet_editor_edit_action(author:, time: Time.zone.now, project:)
          track_unique_action(EDIT_BY_SNIPPET_EDITOR, author, time, project)
        end

        def count_snippet_editor_edit_actions(date_from:, date_to:)
          count_unique(EDIT_BY_SNIPPET_EDITOR, date_from, date_to)
        end

        def count_edit_using_editor(date_from:, date_to:)
          events = Gitlab::UsageDataCounters::HLLRedisCounter.events_for_category(EDIT_CATEGORY)
          count_unique(events, date_from, date_to)
        end

        def track_live_preview_edit_action(author:, time: Time.zone.now, project:)
          track_unique_action(EDIT_BY_LIVE_PREVIEW, author, time, project)
        end

        private

        def track_unique_action(action, author, time, project = nil)
          return unless author

          if Feature.enabled?(:route_hll_to_snowplow_phase2)
            Gitlab::Tracking.event(
              'ide_edit',
              action.to_s,
              project: project,
              namespace: project&.namespace,
              user: author
            )
          end

          Gitlab::UsageDataCounters::HLLRedisCounter.track_event(action, values: author.id, time: time)
        end

        def count_unique(actions, date_from, date_to)
          Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: actions, start_date: date_from, end_date: date_to)
        end
      end
    end
  end
end
