# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    module StageEventModel
      extend ActiveSupport::Concern

      class_methods do
        def upsert_data(data)
          upsert_values = data.map do |row|
            row.values_at(
              :stage_event_hash_id,
              :issuable_id,
              :group_id,
              :project_id,
              :author_id,
              :milestone_id,
              :start_event_timestamp,
              :end_event_timestamp
            )
          end

          value_list = Arel::Nodes::ValuesList.new(upsert_values).to_sql

          query = <<~SQL
          INSERT INTO #{quoted_table_name}
          (
            stage_event_hash_id, 
            #{connection.quote_column_name(issuable_id_column)},
            group_id,
            project_id,
            milestone_id,
            author_id,
            start_event_timestamp,
            end_event_timestamp
          )
          #{value_list}
          ON CONFLICT(stage_event_hash_id, #{issuable_id_column})
          DO UPDATE SET
            group_id = excluded.group_id,
            project_id = excluded.project_id,
            start_event_timestamp = excluded.start_event_timestamp,
            end_event_timestamp = excluded.end_event_timestamp,
            milestone_id = excluded.milestone_id,
            author_id = excluded.author_id
          SQL

          result = connection.execute(query)
          result.cmd_tuples
        end
      end
    end
  end
end
