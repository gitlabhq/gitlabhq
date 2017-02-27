# Generates CSV when given a collection and a mapping.
#
# Example:
#
#     columns = {
#       'Title' => 'title',
#       'Comment' => 'comment',
#       'Author' => -> (post) { post.author.full_name }
#       'Created At (UTC)' => -> (post) { post.created_at&.strftime('%Y-%m-%d %H:%M:%S') }
#     }
#
#     CsvBuilder.new(@posts, columns).render
#
class CsvBuilder
  #
  # * +collection+ - The data collection to be used
  # * +header_to_hash_value+ - A hash of 'Column Heading' => 'value_method'.
  #
  # The value method will be called once for each object in the collection, to
  # determine the value for that row. It can either be the name of a method on
  # the object, or a lamda to call passing in the object.
  def initialize(collection, header_to_value_hash)
    @header_to_value_hash = header_to_value_hash
    @collection = collection
  end

  # Renders the csv to a string
  def render
    CSV.generate do |csv|
      csv << headers

      @collection.find_each do |object|
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
