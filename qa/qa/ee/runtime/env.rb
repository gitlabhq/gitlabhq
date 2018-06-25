# Prepended onto ::QA::Runtime::Env
module QA
  module EE
    module Runtime
      module Env
        def geo_max_db_replication_time
          ENV['GEO_MAX_DB_REPLICATION_TIME']
        end

        def geo_max_file_replication_time
          ENV['GEO_MAX_FILE_REPLICATION_TIME']
        end
      end
    end
  end
end
