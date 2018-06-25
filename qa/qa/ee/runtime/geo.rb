# EE-only singleton
module QA
  module EE
    module Runtime
      module Geo
        extend self

        def default_max_db_replication_time
          120
        end

        def max_db_replication_time
          (QA::Runtime::Env.geo_max_db_replication_time || default_max_db_replication_time).to_f
        end

        def default_max_file_replication_time
          120
        end

        def max_file_replication_time
          (QA::Runtime::Env.geo_max_file_replication_time || default_max_file_replication_time).to_f
        end
      end
    end
  end
end
