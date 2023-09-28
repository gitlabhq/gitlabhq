# frozen_string_literal: true

module Integrations
  class IntegrationList
    def initialize(batch, integration_hash, association)
      @batch = batch
      @integration_hash = integration_hash
      @association = association
    end

    def to_array
      [Integration, columns, values]
    end

    private

    attr_reader :batch, :integration_hash, :association

    def columns
      integration_hash.keys << "#{association}_id"
    end

    def values
      batch.select(:id).map do |record|
        integration_hash.values << record.id
      end
    end
  end
end
