# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module EditorUniqueCounter
      EDIT_BY_SNIPPET_EDITOR = 'g_edit_by_snippet_ide'
      EDIT_BY_SFE = 'g_edit_by_sfe'
      EDIT_BY_WEB_IDE = 'g_edit_by_web_ide'
      EDIT_CATEGORY = 'ide_edit'

      class << self
        def track_web_ide_edit_action(author:, project:)
          track_internal_event(EDIT_BY_WEB_IDE, author, project)
        end

        def count_web_ide_edit_actions(date_from:, date_to:)
          count_unique(EDIT_BY_WEB_IDE, date_from, date_to)
        end

        def track_sfe_edit_action(author:, project:)
          track_internal_event(EDIT_BY_SFE, author, project)
        end

        def count_sfe_edit_actions(date_from:, date_to:)
          count_unique(EDIT_BY_SFE, date_from, date_to)
        end

        def track_snippet_editor_edit_action(author:, project:)
          track_internal_event(EDIT_BY_SNIPPET_EDITOR, author, project)
        end

        def count_snippet_editor_edit_actions(date_from:, date_to:)
          count_unique(EDIT_BY_SNIPPET_EDITOR, date_from, date_to)
        end

        private

        def track_internal_event(event_name, author, project = nil)
          return unless author

          Gitlab::InternalEvents.track_event(
            event_name,
            user: author,
            project: project,
            namespace: project&.namespace
          )
        end

        def count_unique(actions, date_from, date_to)
          Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: actions, start_date: date_from, end_date: date_to)
        end
      end
    end
  end
end
