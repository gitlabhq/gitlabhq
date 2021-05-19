# frozen_string_literal: true

class ServiceList
  def initialize(batch, service_hash, association)
    @batch = batch
    @service_hash = service_hash
    @association = association
  end

  def to_array
    [Integration, columns, values]
  end

  private

  attr_reader :batch, :service_hash, :association

  def columns
    service_hash.keys << "#{association}_id"
  end

  def values
    batch.select(:id).map do |record|
      service_hash.values << record.id
    end
  end
end
