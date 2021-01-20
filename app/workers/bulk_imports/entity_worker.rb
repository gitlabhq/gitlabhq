# frozen_string_literal: true

module BulkImports
  class EntityWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    feature_category :importers

    sidekiq_options retry: false, dead: false

    worker_has_external_dependencies!

    def perform(entity_id)
      entity = BulkImports::Entity.with_status(:started).find_by_id(entity_id)

      if entity
        entity.update!(jid: jid)

        BulkImports::Importers::GroupImporter.new(entity).execute
      end
    end
  end
end
