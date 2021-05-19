# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class RemoveDuplicateCsFindings
      def perform(start_id, stop_id)
      end
    end
  end
end

Gitlab::BackgroundMigration::RemoveDuplicateCsFindings.prepend_mod_with('Gitlab::BackgroundMigration::RemoveDuplicateCsFindings')
