module Gitlab
  module Database
    def self.adapter_name
      connection.adapter_name
    end

    def self.mysql?
      adapter_name.downcase == 'mysql2'
    end

    def self.postgresql?
      adapter_name.downcase == 'postgresql'
    end

    def self.version
      database_version.match(/\A(?:PostgreSQL |)([^\s]+).*\z/)[1]
    end

    def true_value
      if self.class.postgresql?
        "'t'"
      else
        1
      end
    end

    def false_value
      if self.class.postgresql?
        "'f'"
      else
        0
      end
    end

    private

    def self.connection
      ActiveRecord::Base.connection
    end

    def self.database_version
      row = connection.execute("SELECT VERSION()").first

      if postgresql?
        row['version']
      else
        row.first
      end
    end

    def connection
      self.class.connection
    end
  end
end
