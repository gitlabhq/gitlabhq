# frozen_string_literal: true

# ActiveRecord custom method definitions with timezone information.
# See https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/11229

require 'active_record/connection_adapters/abstract/schema_definitions'

module ActiveRecord
  module ConnectionAdapters
    class TableDefinition
      # Appends columns `created_at` and `updated_at` to a table.
      #
      # It is used in table creation like:
      # create_table 'users' do |t|
      #   t.timestamps_with_timezone
      # end
      def timestamps_with_timezone(**options)
        options[:null] = false if options[:null].nil?

        [:created_at, :updated_at].each do |column_name|
          column(column_name, :datetime_with_timezone, **options)
        end
      end

      # Adds specified column with appropriate timestamp type
      #
      # It is used in table creation like:
      # create_table 'users' do |t|
      #   t.datetime_with_timezone :did_something_at
      # end
      def datetime_with_timezone(column_name, **options)
        column(column_name, :datetime_with_timezone, **options)
      end

      # Disable timestamp alias to datetime
      def aliased_types(name, fallback)
        fallback
      end
    end
  end
end
