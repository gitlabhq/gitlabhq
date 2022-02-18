# rubocop:disable Naming/FileName
# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      Observation = Struct.new(
        :version,
        :name,
        :walltime,
        :success,
        :total_database_size_change,
        :query_statistics,
        keyword_init: true
      )
    end
  end
end

# rubocop:enable Naming/FileName
