module Gitlab
  module Database
    def self.mysql?
      ActiveRecord::Base.connection.adapter_name.downcase == 'mysql2'
    end

    def self.postgresql?
      ActiveRecord::Base.connection.adapter_name.downcase == 'postgresql'
    end

    def true_value
      case ActiveRecord::Base.connection.adapter_name.downcase
      when 'postgresql'
        "'t'"
      else
        1
      end
    end

    def false_value
      case ActiveRecord::Base.connection.adapter_name.downcase
      when 'postgresql'
        "'f'"
      else
        0
      end
    end
  end
end
