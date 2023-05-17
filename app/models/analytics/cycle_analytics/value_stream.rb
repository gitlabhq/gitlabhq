# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class ValueStream < ApplicationRecord
      self.table_name = :analytics_cycle_analytics_group_value_streams

      include Analytics::CycleAnalytics::Parentable

      has_many :stages, -> { ordered },
        class_name: 'Analytics::CycleAnalytics::Stage',
        foreign_key: :group_value_stream_id,
        index_errors: true,
        inverse_of: :value_stream

      validates :name, presence: true
      validates :name, length: { minimum: 3, maximum: 100, allow_nil: false }, uniqueness: { scope: :group_id }

      accepts_nested_attributes_for :stages, allow_destroy: true

      scope :preload_associated_models, -> {
        includes(:namespace, stages: [:namespace, :end_event_label, :start_event_label])
      }

      after_save :ensure_aggregation_record_presence

      def custom?
        persisted? || name != Analytics::CycleAnalytics::Stages::BaseService::DEFAULT_VALUE_STREAM_NAME
      end

      def self.build_default_value_stream(namespace)
        new(name: Analytics::CycleAnalytics::Stages::BaseService::DEFAULT_VALUE_STREAM_NAME, namespace: namespace)
      end

      private

      def ensure_aggregation_record_presence
        Analytics::CycleAnalytics::Aggregation.safe_create_for_namespace(namespace)
      end
    end
  end
end
