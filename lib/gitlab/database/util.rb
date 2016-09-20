module Gitlab
  module Database
    module Util
      class << self
        def run_query(query)
          query = query.to_sql unless query.is_a?(String)
          ActiveRecord::Base.connection.execute(query)
        end
      end
    end
  end
end
