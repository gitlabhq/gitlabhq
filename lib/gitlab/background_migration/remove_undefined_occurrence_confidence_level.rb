# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class RemoveUndefinedOccurrenceConfidenceLevel
      def perform(start_id, stop_id)
      end
    end
  end
end

Gitlab::BackgroundMigration::RemoveUndefinedOccurrenceConfidenceLevel.prepend_mod_with('Gitlab::BackgroundMigration::RemoveUndefinedOccurrenceConfidenceLevel')
