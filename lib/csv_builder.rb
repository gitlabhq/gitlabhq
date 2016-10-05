class CsvBuilder
  def initialize(header_to_value_hash)
    @header_to_value_hash = header_to_value_hash
  end

  def render(collection)
    CSV.generate do |csv|
      csv << headers

      collection.each do |object|
        csv << row(object)
      end
    end
  end

  private

  def headers
    @header_to_value_hash.keys
  end

  def attributes
    @header_to_value_hash.values
  end

  def row(object)
    attributes.map do |attribute|
      if attribute.respond_to?(:call)
        attribute.call(object)
      else
        object.send(attribute)
      end
    end
  end
end
