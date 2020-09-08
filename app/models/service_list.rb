# frozen_string_literal: true

class ServiceList
  def initialize(batch_ids, service_hash)
    @batch_ids = batch_ids
    @service_hash = service_hash
  end

  def to_array
    [Service, columns, values]
  end

  private

  attr_reader :batch_ids, :service_hash

  def columns
    (service_hash.keys << 'project_id')
  end

  def values
    batch_ids.map do |project_id|
      (service_hash.values << project_id)
    end
  end
end
