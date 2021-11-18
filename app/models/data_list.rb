# frozen_string_literal: true

class DataList
  def initialize(batch, data_fields_hash, data_fields_klass)
    @batch = batch
    @data_fields_hash = data_fields_hash
    @data_fields_klass = data_fields_klass
  end

  def to_array
    [data_fields_klass, columns, values]
  end

  private

  attr_reader :batch, :data_fields_hash, :data_fields_klass

  def columns
    data_fields_hash.keys << data_fields_foreign_key
  end

  def data_fields_foreign_key
    data_fields_klass.reflections['integration'].foreign_key
  end

  def values
    batch.map do |record|
      data_fields_hash.values << record['id']
    end
  end
end
