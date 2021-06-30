# frozen_string_literal: true

class BulkUpdateIntegrationService
  def initialize(integration, batch)
    @integration = integration
    @batch = batch
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def execute
    Integration.transaction do
      Integration.where(id: batch.select(:id)).update_all(integration_hash)

      if integration.data_fields_present?
        integration.data_fields.class.where(service_id: batch.select(:id)).update_all(data_fields_hash)
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  attr_reader :integration, :batch

  def integration_hash
    integration.to_integration_hash.tap { |json| json['inherit_from_id'] = integration.inherit_from_id || integration.id }
  end

  def data_fields_hash
    integration.to_data_fields_hash
  end
end
