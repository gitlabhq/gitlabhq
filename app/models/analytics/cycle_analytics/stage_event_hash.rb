# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class StageEventHash < ApplicationRecord
      has_many :cycle_analytics_stages, class_name: 'Analytics::CycleAnalytics::Stage', inverse_of: :stage_event_hash

      validates :hash_sha256, presence: true

      # Creates or queries the id of the corresponding stage event hash code
      def self.record_id_by_hash_sha256(organization_id, hash)
        hash_record = find_by(organization_id: organization_id, hash_sha256: hash)
        return hash_record.id if hash_record

        casted_organization_id = Arel::Nodes
          .build_quoted(organization_id, arel_table[:organization_id])
          .to_sql

        casted_hash_code = Arel::Nodes
          .build_quoted(hash, arel_table[:hash_sha256])
          .to_sql

        # Atomic, safe insert without retrying
        query = <<~SQL
        WITH insert_cte AS MATERIALIZED (
          INSERT INTO #{quoted_table_name} (organization_id, hash_sha256) VALUES (#{casted_organization_id}, #{casted_hash_code}) ON CONFLICT DO NOTHING RETURNING ID
        )
        SELECT ids.id FROM (
          (SELECT id FROM #{quoted_table_name} WHERE organization_id=#{casted_organization_id} AND hash_sha256=#{casted_hash_code} LIMIT 1)
            UNION ALL
          (SELECT id FROM insert_cte LIMIT 1)
        ) AS ids LIMIT 1
        SQL

        connection.execute(query).first['id']
      end

      def self.cleanup_if_unused(id)
        unused_hashes_for(id)
          .where(id: id)
          .delete_all
      end

      def self.unused_hashes_for(id)
        stage_exists_query = ::Analytics::CycleAnalytics::Stage.where(stage_event_hash_id: id).select('1').limit(1)

        where.not('EXISTS (?)', stage_exists_query)
      end
    end
  end
end
