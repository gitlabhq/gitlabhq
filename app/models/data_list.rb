# frozen_string_literal: true

class DataList
  def initialize(batch_ids, data_fields_hash, klass)
    @batch_ids = batch_ids
    @data_fields_hash = data_fields_hash
    @klass = klass
  end

  def to_array
    [klass, columns, values]
  end

  private

  attr_reader :batch_ids, :data_fields_hash, :klass

  def columns
    data_fields_hash.keys << 'service_id'
  end

  def values
    batch_ids.map do |row|
      data_fields_hash.values << row['id']
    end
  end
end
