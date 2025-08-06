# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateAiCodeSuggestionEvents < BatchedMigrationJob
      operation_name :copy_ai_code_suggestion_events
      feature_category :value_stream_management

      def perform
        # no-op for CE
      end
    end
  end
end

Gitlab::BackgroundMigration::MigrateAiCodeSuggestionEvents.prepend_mod
