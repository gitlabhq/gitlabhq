# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class RemoveUndefinedOccurrenceSeverityLevel
      def perform(start_id, stop_id)
      end
    end
  end
end

Gitlab::BackgroundMigration::RemoveUndefinedOccurrenceSeverityLevel.prepend_mod_with('Gitlab::BackgroundMigration::RemoveUndefinedOccurrenceSeverityLevel')
