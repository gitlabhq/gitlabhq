# frozen_string_literal: true

class ServiceList
  def initialize(batch_ids, service_hash, association)
    @batch_ids = batch_ids
    @service_hash = service_hash
    @association = association
  end

  def to_array
    [Service, columns, values]
  end

  private

  attr_reader :batch_ids, :service_hash, :association

  def columns
    (service_hash.keys << "#{association}_id")
  end

  def values
    batch_ids.map do |id|
      (service_hash.values << id)
    end
  end
end
