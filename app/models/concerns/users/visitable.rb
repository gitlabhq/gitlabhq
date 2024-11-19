# frozen_string_literal: true

module Users
  module Visitable
    extend ActiveSupport::Concern

    included do
      def self.visited_around?(entity_id:, user_id:, time:)
        visits_around(entity_id: entity_id, user_id: user_id, time: time).any?
      end

      def self.visits_around(entity_id:, user_id:, time:)
        time = time.to_datetime
        where(entity_id: entity_id, user_id: user_id, visited_at: (time - 15.minutes)..(time + 15.minutes))
      end

      scope :for_user, ->(user_id) { where(user_id: user_id) }

      scope :recently_visited, -> do
        where('visited_at > ?', 3.months.ago)
          .where('visited_at <= ?', Time.current)
      end

      def self.grouped_by_week_start_and_entity_for_user(user_id:)
        recently_visited
          .for_user(user_id)
          .group(:week_start, :entity_id)
          .select(
            :entity_id,
            "COUNT(entity_id) AS week_count",
            "DATE_TRUNC('week', visited_at)::date AS week_start",
            "DENSE_RANK() OVER (ORDER BY DATE_TRUNC('week', visited_at)::date)"
          )
      end

      def self.frecent_visits_scores(user_id:, limit:)
        ranked_entity_visits_query = grouped_by_week_start_and_entity_for_user(user_id: user_id).to_sql
        sql = <<~SQL
          SELECT
            entity_id,
            SUM(week_count * dense_rank) AS score
          FROM
            (#{ranked_entity_visits_query}) as ranked_entity_visits
          GROUP BY
            entity_id
          ORDER BY
            score DESC
          LIMIT #{limit}
        SQL

        ::Gitlab::Database::LoadBalancing::SessionMap
          .current(load_balancer).fallback_to_replicas_for_ambiguous_queries do
          connection.execute(sql).to_a
        end
      end
    end
  end
end
