# frozen_string_literal: true

module Gitlab
  module Database
    # Use this model with care: Retrieving bloat statistics
    # for all indexes can be expensive in a large database.
    #
    # Best used on a per-index basis.
    class PostgresIndexBloatEstimate < SharedModel
      self.table_name = 'postgres_index_bloat_estimates'
      self.primary_key = 'identifier'

      belongs_to :index, foreign_key: :identifier, class_name: 'Gitlab::Database::PostgresIndex'

      alias_attribute :bloat_size, :bloat_size_bytes
    end
  end
end
