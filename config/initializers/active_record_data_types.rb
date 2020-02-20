# ActiveRecord custom data type for storing datetimes with timezone information.
# See https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/11229

require 'active_record/connection_adapters/postgresql_adapter'

module ActiveRecord::ConnectionAdapters::PostgreSQL::OID
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
  def initialize_type_map(mapping = type_map)
    super mapping

    register_class_with_precision(
      mapping,
      'timestamptz',
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::DateTimeWithTimeZone
    )
  end
end

class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  prepend RegisterDateTimeWithTimeZone

  # Add column type `datetime_with_timezone` so we can do this in
  # migrations:
  #
  #   add_column(:users, :datetime_with_timezone)
  #
  NATIVE_DATABASE_TYPES[:datetime_with_timezone] = { name: 'timestamptz' }
end

# Ensure `datetime_with_timezone` columns are correctly written to schema.rb
if (ActiveRecord::Base.connection.active? rescue false)
  ActiveRecord::Base.connection.send :reload_type_map
end

ActiveRecord::Base.time_zone_aware_types += [:datetime_with_timezone]
