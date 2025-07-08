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

    def self.load_outdated_batch(batch_size)
      where
        .not(outdated_at: nil)
        .limit(batch_size)
        .lock('FOR UPDATE SKIP LOCKED')
        .pluck_primary_key
    end

    def self.upsert_with_consistent_data(namespace:, self_and_descendant_group_ids:, all_project_ids:, outdated_at: nil)
      query = <<~SQL
        INSERT INTO namespace_descendants
        (namespace_id, traversal_ids, self_and_descendant_group_ids, all_project_ids, outdated_at, calculated_at)
        VALUES
        (
          ?,
          ARRAY[?]::bigint[],
          ARRAY_REMOVE(ARRAY[?]::bigint[], NULL),
          ARRAY_REMOVE(ARRAY[?]::bigint[], NULL),
          NULL,
          ?
        )
        ON CONFLICT(namespace_id)
        DO UPDATE SET
          traversal_ids = EXCLUDED.traversal_ids,
          self_and_descendant_group_ids = EXCLUDED.self_and_descendant_group_ids,
          all_project_ids = EXCLUDED.all_project_ids,
          #{handle_outdated_at(outdated_at)}
          calculated_at = EXCLUDED.calculated_at
      SQL

      connection.execute(sanitize_sql_array([
        query,
        namespace.id,
        namespace.traversal_ids,
        self_and_descendant_group_ids,
        all_project_ids,
        Time.current
      ]))
    end

    def self.handle_outdated_at(previous_outdated_at)
      if previous_outdated_at
        # When the cache is outdated, the outdated_at column is always bumped.
        # Here we only mark the namespace_descendants record up to date
        # when the outdated_at value is exactly the same as the outdated_at loaded earlier.
        quoted = Namespaces::Descendants.connection.quote(previous_outdated_at)
        <<~SQL
        outdated_at = CASE
          WHEN namespace_descendants.outdated_at = #{quoted} THEN NULL
          ELSE namespace_descendants.outdated_at
        END,
        SQL
      else
        "outdated_at = EXCLUDED.outdated_at,"
      end
    end

    private_class_method :handle_outdated_at
  end
end
