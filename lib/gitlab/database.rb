module Gitlab
  module Database
    def self.mysql?
      ActiveRecord::Base.connection.adapter_name.downcase == 'mysql2'
    end

    def self.postgresql?
      ActiveRecord::Base.connection.adapter_name.downcase == 'postgresql'
    end
  end
end
