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
        # Looking up the whole hierarchy including all kinds (type) of Namespace records.
        # We're doing a custom traversal_ids query because:
        # - The traversal_ids based `self_and_descendants` doesn't include the ProjectNamespace records.
        # - The default recursive lookup also excludes the ProjectNamespace records.
        #
        # Related issue: https://gitlab.com/gitlab-org/gitlab/-/issues/386124
        all_namespace_ids =
          Namespace
          .select(Arel.sql('namespaces.traversal_ids[array_length(namespaces.traversal_ids, 1)]').as('id'))
          .where("traversal_ids @> ('{?}')", namespace.id)

        with_preloaded_labels
          .where(parent_id: all_namespace_ids)
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
