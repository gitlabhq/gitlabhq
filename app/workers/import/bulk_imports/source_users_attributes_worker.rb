# frozen_string_literal: true

module Import
  module BulkImports
    class SourceUsersAttributesWorker
      include ApplicationWorker

      idempotent!
      data_consistency :delayed
      feature_category :importers
      sidekiq_options retry: 6, dead: false
      sidekiq_options max_retries_after_interruption: 20
      worker_has_external_dependencies!

      PERFORM_DELAY = 5.minutes

      def perform(bulk_import_id)
        bulk_import = BulkImport.find_by_id(bulk_import_id)
        return unless bulk_import

        portables = bulk_import.entities.filter_map { |entity| entity.group || entity.project }
        root_ancestors = portables.map(&:root_ancestor).uniq
        root_ancestors.each do |root_ancestor|
          UpdateSourceUsersService.new(namespace: root_ancestor, bulk_import: bulk_import).execute
        end

        # Stop re-enqueueing when the import is completed
        self.class.perform_in(PERFORM_DELAY, bulk_import_id) unless bulk_import.completed?
      end
    end
  end
end
