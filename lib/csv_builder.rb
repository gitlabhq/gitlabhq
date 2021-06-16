# frozen_string_literal: true

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
  DEFAULT_ORDER_BY = 'id'
  DEFAULT_BATCH_SIZE = 1000
  PREFIX_REGEX = /\A[=\+\-@;]/.freeze

  attr_reader :rows_written

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
    @truncated = false
    @rows_written = 0
  end

  # Renders the csv to a string
  def render(truncate_after_bytes = nil)
    Tempfile.open(['csv']) do |tempfile|
      csv = CSV.new(tempfile)

      write_csv csv, until_condition: -> do
        truncate_after_bytes && tempfile.size > truncate_after_bytes
      end

      if block_given?
        yield tempfile
      else
        tempfile.rewind
        tempfile.read
      end
    end
  end

  def truncated?
    @truncated
  end

  def rows_expected
    if truncated? || rows_written == 0
      @collection.count
    else
      rows_written
    end
  end

  def status
    {
      truncated: truncated?,
      rows_written: rows_written,
      rows_expected: rows_expected
    }
  end

  protected

  def each(&block)
    @collection.find_each(&block) # rubocop: disable CodeReuse/ActiveRecord
  end

  private

  def headers
    @headers ||= @header_to_value_hash.keys
  end

  def attributes
    @attributes ||= @header_to_value_hash.values
  end

  def row(object)
    attributes.map do |attribute|
      if attribute.respond_to?(:call)
        excel_sanitize(attribute.call(object))
      else
        excel_sanitize(object.public_send(attribute)) # rubocop:disable GitlabSecurity/PublicSend
      end
    end
  end

  def write_csv(csv, until_condition:)
    csv << headers

    each do |object|
      csv << row(object)

      @rows_written += 1

      if until_condition.call
        @truncated = true
        break
      end
    end
  end

  def excel_sanitize(line)
    return if line.nil?
    return line unless line.is_a?(String) && line.match?(PREFIX_REGEX)

    ["'", line].join
  end
end
