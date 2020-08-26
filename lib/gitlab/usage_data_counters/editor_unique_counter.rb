# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module EditorUniqueCounter
      EDIT_BY_SNIPPET_EDITOR = :edit_by_snippet_editor
      EDIT_BY_SFE = :edit_by_sfe
      EDIT_BY_WEB_IDE = :edit_by_web_ide

      class << self
        def track_web_ide_edit_action(author:, time: Time.zone.now)
          track_unique_action(EDIT_BY_WEB_IDE, author, time)
        end

        def count_web_ide_edit_actions(date_from:, date_to:)
          count_unique(EDIT_BY_WEB_IDE, date_from, date_to)
        end

        def track_sfe_edit_action(author:, time: Time.zone.now)
          track_unique_action(EDIT_BY_SFE, author, time)
        end

        def count_sfe_edit_actions(date_from:, date_to:)
          count_unique(EDIT_BY_SFE, date_from, date_to)
        end

        def track_snippet_editor_edit_action(author:, time: Time.zone.now)
          track_unique_action(EDIT_BY_SNIPPET_EDITOR, author, time)
        end

        def count_snippet_editor_edit_actions(date_from:, date_to:)
          count_unique(EDIT_BY_SNIPPET_EDITOR, date_from, date_to)
        end

        private

        def track_unique_action(action, author, time)
          return unless Feature.enabled?(:track_editor_edit_actions)

          Gitlab::UsageDataCounters::TrackUniqueActions.track_action(action: action, author_id: author.id, time: time)
        end

        def count_unique(action, date_from, date_to)
          Gitlab::UsageDataCounters::TrackUniqueActions.count_unique(action: action, date_from: date_from, date_to: date_to)
        end
      end
    end
  end
end
