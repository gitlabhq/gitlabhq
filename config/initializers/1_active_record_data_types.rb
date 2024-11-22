# frozen_string_literal: true

# ActiveRecord custom data type for storing datetimes with timezone information.
# See https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/11229

require 'active_record/connection_adapters/postgresql_adapter'

module ActiveRecord::ConnectionAdapters::PostgreSQL::OID # rubocop:disable Style/ClassAndModuleChildren
  # Add the class `DateTimeWithTimeZone` so we can map `timestamptz` to it.
  class DateTimeWithTimeZone < DateTime
    def type
      :datetime_with_timezone
    end
  end
end

module RegisterDateTimeWithTimeZone
  # Run original `initialize_type_map` and then register `timestamptz` as a
  # `DateTimeWithTimeZone`.
  #
  # Apparently it does not matter that the original `initialize_type_map`
  # aliases `timestamptz` to `timestamp`.
  #
  # When schema dumping, `timestamptz` columns will be output as
  # `t.datetime_with_timezone`.
  class << self
    def initialize_type_map(mapping = type_map)
      super mapping

      register_class_with_precision(
        mapping,
        'timestamptz',
        ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::DateTimeWithTimeZone
      )
    end
  end
end

class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter # rubocop:disable Style/ClassAndModuleChildren
  prepend RegisterDateTimeWithTimeZone

  # Add column type `datetime_with_timezone` so we can do this in
  # migrations:
  #
  #   add_column(:users, :datetime_with_timezone)
  #
  NATIVE_DATABASE_TYPES[:datetime_with_timezone] = { name: 'timestamptz' }
end

def connection_active?
  ActiveRecord::Base.connection.active? # rubocop:disable Database/MultipleDatabases
rescue StandardError
  false
end

# Ensure `datetime_with_timezone` columns are correctly written to schema.rb

# rubocop:disable Database/MultipleDatabases
ActiveRecord::Base.connection.send(:reload_type_map) if connection_active?

ActiveRecord::Base.time_zone_aware_types += [:datetime_with_timezone]
# rubocop:enable Database/MultipleDatabases
