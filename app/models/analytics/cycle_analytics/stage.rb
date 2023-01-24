# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class Stage < ApplicationRecord
      self.table_name = :analytics_cycle_analytics_group_stages

      include DatabaseEventTracking
      include Analytics::CycleAnalytics::Stageable
      include Analytics::CycleAnalytics::Parentable

      validates :name, uniqueness: { scope: [:group_id, :group_value_stream_id] }
      belongs_to :value_stream, class_name: 'Analytics::CycleAnalytics::ValueStream',
foreign_key: :group_value_stream_id, inverse_of: :stages

      alias_attribute :parent, :namespace
      alias_attribute :parent_id, :group_id
      alias_attribute :value_stream_id, :group_value_stream_id

      def self.distinct_stages_within_hierarchy(namespace)
        with_preloaded_labels
          .where(group_id: namespace.self_and_descendants.select(:id))
          .select("DISTINCT ON(stage_event_hash_id) #{quoted_table_name}.*")
      end

      SNOWPLOW_ATTRIBUTES = %i[
        id
        created_at
        updated_at
        relative_position
        start_event_identifier
        end_event_identifier
        group_id
        start_event_label_id
        end_event_label_id
        hidden
        custom
        name
        group_value_stream_id
      ].freeze
    end
  end
end
