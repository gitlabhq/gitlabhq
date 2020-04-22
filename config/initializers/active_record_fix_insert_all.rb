# frozen_string_literal: true

# This fix is needed to properly support
# columns that perform data mutation to a SQL datatype
# ex. would be `jsonb` and `enum`
#
# This is covered by tests in `BulkInsertSafe`
# that validates handling of different data types

if Rails.gem_version > Gem::Version.new("6.0.2.2")
  raise Gem::DependencyError,
    "Remove patch once the https://github.com/rails/rails/pull/38763 is included"
end

module ActiveRecordInsertAllBuilderMixin
  def extract_types_from_columns_on(table_name, keys:)
    columns = connection.schema_cache.columns_hash(table_name)

    unknown_column = (keys - columns.keys).first
    raise UnknownAttributeError.new(model.new, unknown_column) if unknown_column

    keys.index_with { |key| model.type_for_attribute(key) }
  end
end

ActiveRecord::InsertAll::Builder.prepend(ActiveRecordInsertAllBuilderMixin)
