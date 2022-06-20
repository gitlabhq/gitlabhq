# frozen_string_literal: true

class BulkUpdateIntegrationService
  include Integrations::BulkOperationHashes

  def initialize(integration, batch)
    @integration = integration
    @batch = batch
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def execute
    Integration.transaction do
      Integration.where(id: batch_ids).update_all(integration_hash(:update))

      if integration.data_fields_present?
        integration.data_fields.class.where(data_fields_foreign_key => batch_ids)
          .update_all(
            data_fields_hash(:update)
          )
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  attr_reader :integration, :batch

  # service_id or integration_id
  def data_fields_foreign_key
    integration.data_fields.class.reflections['integration'].foreign_key
  end

  def batch_ids
    @batch_ids ||=
      if batch.is_a?(ActiveRecord::Relation)
        batch.select(:id)
      else
        batch.map(&:id)
      end
  end
end
