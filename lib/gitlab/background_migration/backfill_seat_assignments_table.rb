# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSeatAssignmentsTable < BatchedMigrationJob
      feature_category :seat_cost_management

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillSeatAssignmentsTable.prepend_mod
