# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    module Stage
      extend ActiveSupport::Concern
      include RelativePositioning

      included do
        validates :name, presence: true
        validates :name, exclusion: { in: Gitlab::Analytics::CycleAnalytics::DefaultStages.names }, if: :custom?
        validates :start_event_identifier, presence: true
        validates :end_event_identifier, presence: true
        validate :validate_stage_event_pairs

        enum start_event_identifier: Gitlab::Analytics::CycleAnalytics::StageEvents.to_enum, _prefix: :start_event_identifier
        enum end_event_identifier: Gitlab::Analytics::CycleAnalytics::StageEvents.to_enum, _prefix: :end_event_identifier

        alias_attribute :custom_stage?, :custom
        scope :default_stages, -> { where(custom: false) }
        scope :ordered, -> { order(:relative_position, :id) }
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

      # The model class that is going to be queried, Issue or MergeRequest
      def subject_class
        start_event.object_type
      end

      def matches_with_stage_params?(stage_params)
        default_stage? &&
          start_event_identifier.to_s.eql?(stage_params[:start_event_identifier].to_s) &&
          end_event_identifier.to_s.eql?(stage_params[:end_event_identifier].to_s)
      end

      def find_with_same_parent!(id)
        parent.cycle_analytics_stages.find(id)
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
