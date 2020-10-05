# frozen_string_literal: true

class DataList
  def initialize(batch, data_fields_hash, klass)
    @batch = batch
    @data_fields_hash = data_fields_hash
    @klass = klass
  end

  def to_array
    [klass, columns, values]
  end

  private

  attr_reader :batch, :data_fields_hash, :klass

  def columns
    data_fields_hash.keys << 'service_id'
  end

  def values
    batch.map do |record|
      data_fields_hash.values << record['id']
    end
  end
end
