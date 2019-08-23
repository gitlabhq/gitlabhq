# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    module Stage
      extend ActiveSupport::Concern

      included do
        validates :name, presence: true
        validates :start_event_identifier, presence: true
        validates :end_event_identifier, presence: true
        validate :validate_stage_event_pairs

        enum start_event_identifier: Gitlab::Analytics::CycleAnalytics::StageEvents.to_enum, _prefix: :start_event_identifier
        enum end_event_identifier: Gitlab::Analytics::CycleAnalytics::StageEvents.to_enum, _prefix: :end_event_identifier

        alias_attribute :custom_stage?, :custom
      end

      def parent=(_)
        raise NotImplementedError
      end

      def parent
        raise NotImplementedError
      end

      def start_event
        Gitlab::Analytics::CycleAnalytics::StageEvents[start_event_identifier].new(params_for_start_event)
      end

      def end_event
        Gitlab::Analytics::CycleAnalytics::StageEvents[end_event_identifier].new(params_for_end_event)
      end

      def params_for_start_event
        {}
      end

      def params_for_end_event
        {}
      end

      def default_stage?
        !custom
      end

      # The model that is going to be queried, Issue or MergeRequest
      def subject_model
        start_event.object_type
      end

      private

      def validate_stage_event_pairs
        return if start_event_identifier.nil? || end_event_identifier.nil?

        unless pairing_rules.fetch(start_event.class, []).include?(end_event.class)
          errors.add(:end_event, :not_allowed_for_the_given_start_event)
        end
      end

      def pairing_rules
        Gitlab::Analytics::CycleAnalytics::StageEvents.pairing_rules
      end
    end
  end
end
