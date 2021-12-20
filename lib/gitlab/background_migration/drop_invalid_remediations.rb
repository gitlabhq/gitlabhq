# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Style/Documentation
    class DropInvalidRemediations
      def perform(start_id, stop_id)
      end
    end
    # rubocop: enable Style/Documentation
  end
end

Gitlab::BackgroundMigration::DropInvalidRemediations.prepend_mod_with('Gitlab::BackgroundMigration::DropInvalidRemediations')
