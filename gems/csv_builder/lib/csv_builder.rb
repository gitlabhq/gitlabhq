# frozen_string_literal: true

require 'csv'
require 'tempfile'
require 'zlib'

require_relative "csv_builder/version"
require_relative "csv_builder/builder"
require_relative "csv_builder/single_batch"
require_relative "csv_builder/stream"
require_relative "csv_builder/gzip"

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
module CsvBuilder
  #
  # * +collection+ - The data collection to be used
  # * +header_to_value_hash+ - A hash of 'Column Heading' => 'value_method'.
  # * +associations_to_preload+ - An array of records to preload with a batch of records.
  # * +replace_newlines+ - default: false - If true, replaces newline characters with a literal "\n"
  # * +order_hint+ - default: :created_at - The column used to order the rows
  #
  # The value method will be called once for each object in the collection, to
  # determine the value for that row. It can either be the name of a method on
  # the object, or a lamda to call passing in the object.
  def self.new(
    collection, header_to_value_hash, associations_to_preload = [], replace_newlines: false,
    order_hint: :created_at)
    CsvBuilder::Builder.new(
      collection,
      header_to_value_hash,
      associations_to_preload,
      replace_newlines: replace_newlines,
      order_hint: order_hint
    )
  end
end
