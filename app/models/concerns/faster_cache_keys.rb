# frozen_string_literal: true

module FasterCacheKeys
  # A faster version of Rails' "cache_key" method.
  #
  # Rails' default "cache_key" method uses all kind of complex logic to figure
  # out the cache key. In many cases this complexity and overhead may not be
  # needed.
  #
  # This method does not do any timestamp parsing as this process is quite
  # expensive and not needed when generating cache keys. This method also relies
  # on the table name instead of the cache namespace name as the latter uses
  # complex logic to generate the exact same value (as when using the table
  # name) in 99% of the cases.
  def cache_key
    "#{self.class.table_name}/#{id}-#{read_attribute_before_type_cast(:updated_at)}"
  end
end
