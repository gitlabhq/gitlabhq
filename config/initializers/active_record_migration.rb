require 'active_record/migration'

module ActiveRecord
  class Migration
    # data_source_exists? is not available in 4.2.10, table_exists deprecated in 5.0
    def table_exists?(table_name)
      ActiveRecord::Base.connection.data_source_exists?(table_name)
    end
  end
end
