# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      Observation = Struct.new(
        :migration,
        :walltime,
        :success,
        :total_database_size_change,
        :query_statistics
      )
    end
  end
end
