# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # No op on CE
    class MigrateRequirementsToWorkItems
      def perform(start_id, end_id); end
    end
  end
end

Gitlab::BackgroundMigration::MigrateRequirementsToWorkItems.prepend_mod_with('Gitlab::BackgroundMigration::MigrateRequirementsToWorkItems')
