# frozen_string_literal: true

module Clusters
  module Migration
    class InstallAgentWorker
      include ApplicationWorker
      include ClusterQueue

      deduplicate :until_executed, including_scheduled: true
      idempotent!

      urgency :low
      data_consistency :delayed

      def perform(migration_id)
        migration = Clusters::AgentMigration.find_by_id(migration_id)
        return unless migration.present?

        Clusters::Migration::InstallAgentService.new(migration).execute
      end
    end
  end
end
