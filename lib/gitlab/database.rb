module Gitlab
  module Database
    # The max value of INTEGER type is the same between MySQL and PostgreSQL:
    # https://www.postgresql.org/docs/9.2/static/datatype-numeric.html
    # http://dev.mysql.com/doc/refman/5.7/en/integer-types.html
    MAX_INT_VALUE = 2147483647

    def self.adapter_name
      connection.adapter_name
    end

    def self.mysql?
      adapter_name.casecmp('mysql2').zero?
    end

    def self.postgresql?
      adapter_name.casecmp('postgresql').zero?
    end

    def self.version
      database_version.match(/\A(?:PostgreSQL |)([^\s]+).*\z/)[1]
    end

    def self.nulls_last_order(field, direction = 'ASC')
      order = "#{field} #{direction}"

      if Gitlab::Database.postgresql?
        order << ' NULLS LAST'
      else
        # `field IS NULL` will be `0` for non-NULL columns and `1` for NULL
        # columns. In the (default) ascending order, `0` comes first.
        order.prepend("#{field} IS NULL, ") if direction == 'ASC'
      end

      order
    end

    def self.random
      Gitlab::Database.postgresql? ? "RANDOM()" : "RAND()"
    end

    def true_value
      if Gitlab::Database.postgresql?
        "'t'"
      else
        1
      end
    end

    def false_value
      if Gitlab::Database.postgresql?
        "'f'"
      else
        0
      end
    end

    def self.connection
      ActiveRecord::Base.connection
    end

    private_class_method :connection

    def self.database_version
      row = connection.execute("SELECT VERSION()").first

      if postgresql?
        row['version']
      else
        row.first
      end
    end

    private_class_method :database_version
  end
end
