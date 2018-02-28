# Make sure that MySQL won't try to use CURRENT_TIMESTAMP when the timestamp
# column is NOT NULL. See https://gitlab.com/gitlab-org/gitlab-ce/issues/36405
# And also: https://bugs.mysql.com/bug.php?id=75098
# This patch was based on:
# https://github.com/rails/rails/blob/15ef55efb591e5379486ccf53dd3e13f416564f6/activerecord/lib/active_record/connection_adapters/mysql/schema_creation.rb#L34-L36

if Gitlab::Database.mysql?
  require 'active_record/connection_adapters/abstract/schema_creation'

  module MySQLTimestampFix
    def add_column_options!(sql, options)
      # By default, TIMESTAMP columns are NOT NULL, cannot contain NULL values,
      # and assigning NULL assigns the current timestamp. To permit a TIMESTAMP
      # column to contain NULL, explicitly declare it with the NULL attribute.
      # See http://dev.mysql.com/doc/refman/5.7/en/timestamp-initialization.html
      if sql.end_with?('timestamp') && !options[:primary_key]
        if options[:null] != false
          sql << ' NULL'
        elsif options[:column].default.nil?
          sql << ' DEFAULT 0'
        end
      end

      super
    end
  end

  ActiveRecord::ConnectionAdapters::AbstractAdapter::SchemaCreation
    .prepend(MySQLTimestampFix)
end
