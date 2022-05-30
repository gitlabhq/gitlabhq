# frozen_string_literal: true

class BulkCreateIntegrationService
  include Integrations::BulkOperationHashes

  def initialize(integration, batch, association)
    @integration = integration
    @batch = batch
    @association = association
  end

  def execute
    service_list = ServiceList.new(batch, integration_hash(:create), association).to_array

    Integration.transaction do
      results = bulk_insert(*service_list)

      if integration.data_fields_present?
        data_list = DataList.new(results, data_fields_hash(:create), integration.data_fields.class).to_array

        bulk_insert(*data_list)
      end
    end
  end

  private

  attr_reader :integration, :batch, :association

  def bulk_insert(klass, columns, values_array)
    items_to_insert = values_array.map { |array| Hash[columns.zip(array)] }

    klass.insert_all(items_to_insert, returning: [:id])
  end
end
