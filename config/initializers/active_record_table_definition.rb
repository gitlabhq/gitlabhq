# ActiveRecord custom method definitions with timezone information.
# See https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/11229

require 'active_record/connection_adapters/abstract/schema_definitions'

# Appends columns `created_at` and `updated_at` to a table.
#
# It is used in table creation like:
# create_table 'users' do |t|
#   t.timestamps_with_timezone
# end
module ActiveRecord
  module ConnectionAdapters
    class TableDefinition
      def timestamps_with_timezone(**options)
        options[:null] = false if options[:null].nil?

        [:created_at, :updated_at].each do |column_name|
          column(column_name, :datetime_with_timezone, options)
        end
      end
    end
  end
end
