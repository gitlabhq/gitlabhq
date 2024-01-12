# frozen_string_literal: true

module Namespaces
  class Descendants < ApplicationRecord
    self.table_name = :namespace_descendants

    belongs_to :namespace

    validates :namespace_id, uniqueness: true

    def self.expire_for(namespace_ids)
      # Union:
      # - Look up all parent ids including the given ids via traversal_ids
      # - Include the given ids to handle the case when the namespaces records are already deleted
      sql = <<~SQL
      WITH namespace_ids AS MATERIALIZED (
        (
          SELECT ids.id
          FROM namespaces, UNNEST(traversal_ids) ids(id)
          WHERE namespaces.id IN (?)
        ) UNION
        (SELECT UNNEST(ARRAY[?]) AS id)
      )
      UPDATE namespace_descendants SET outdated_at = ? FROM namespace_ids WHERE namespace_descendants.namespace_id = namespace_ids.id
      SQL

      connection.execute(sanitize_sql_array([sql, namespace_ids, namespace_ids, Time.current]))
    end
  end
end
