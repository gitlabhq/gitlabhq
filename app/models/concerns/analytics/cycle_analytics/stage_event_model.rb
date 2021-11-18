# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    module StageEventModel
      extend ActiveSupport::Concern

      included do
        scope :by_stage_event_hash_id, ->(id) { where(stage_event_hash_id: id) }
        scope :by_project_id, ->(id) { where(project_id: id) }
        scope :by_group_id, ->(id) { where(group_id: id) }
        scope :end_event_timestamp_after, -> (date) { where(arel_table[:end_event_timestamp].gteq(date)) }
        scope :end_event_timestamp_before, -> (date) { where(arel_table[:end_event_timestamp].lteq(date)) }
        scope :start_event_timestamp_after, -> (date) { where(arel_table[:start_event_timestamp].gteq(date)) }
        scope :start_event_timestamp_before, -> (date) { where(arel_table[:start_event_timestamp].lteq(date)) }
        scope :authored, ->(user) { where(author_id: user) }
        scope :with_milestone_id, ->(milestone_id) { where(milestone_id: milestone_id) }
        scope :end_event_is_not_happened_yet, -> { where(end_event_timestamp: nil) }
      end

      def issuable_id
        attributes[self.class.issuable_id_column.to_s]
      end

      class_methods do
        def upsert_data(data)
          upsert_values = data.map do |row|
            row.values_at(
              :stage_event_hash_id,
              :issuable_id,
              :group_id,
              :project_id,
              :milestone_id,
              :author_id,
              :state_id,
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
            state_id,
            start_event_timestamp,
            end_event_timestamp
          )
          #{value_list}
          ON CONFLICT(stage_event_hash_id, #{issuable_id_column})
          DO UPDATE SET
            group_id = excluded.group_id,
            project_id = excluded.project_id,
            milestone_id = excluded.milestone_id,
            author_id = excluded.author_id,
            state_id = excluded.state_id,
            start_event_timestamp = excluded.start_event_timestamp,
            end_event_timestamp = excluded.end_event_timestamp
          SQL

          result = connection.execute(query)
          result.cmd_tuples
        end
      end
    end
  end
end
