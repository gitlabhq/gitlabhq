# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      Observation = Struct.new(:version, :name, :walltime, :success, :total_database_size_change, :error_message,
        :meta, :query_statistics, keyword_init: true) do
        def to_json(...)
          as_json.except('meta').to_json(...)
        end
      end
    end
  end
end
