# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Resets inconsistent state of shared_runners_enabled for projects that have been transferred
    class ResetSharedRunnersForTransferredProjects
      # Model specifically used for migration.
      class Namespace < ActiveRecord::Base
        include EachBatch

        self.table_name = 'namespaces'
      end

      # Model specifically used for migration.
      class Project < ActiveRecord::Base
        self.table_name = 'projects'
      end

      def perform(start_id, stop_id)
        Project.reset_column_information

        Namespace.where(id: start_id..stop_id).each_batch(of: 1_000) do |relation|
          ids = relation.where(shared_runners_enabled: false, allow_descendants_override_disabled_shared_runners: false).select(:id)

          Project.where(namespace_id: ids).update_all(shared_runners_enabled: false)
        end
      end
    end
  end
end
