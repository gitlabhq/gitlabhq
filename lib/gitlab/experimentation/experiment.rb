# frozen_string_literal: true

module Gitlab
  module Experimentation
    class Experiment
      FEATURE_FLAG_SUFFIX = "_experiment_percentage"

      attr_reader :key, :tracking_category, :use_backwards_compatible_subject_index, :rollout_strategy

      def initialize(key, **params)
        @key = key
        @tracking_category = params[:tracking_category]
        @use_backwards_compatible_subject_index = params[:use_backwards_compatible_subject_index]
        @rollout_strategy = params[:rollout_strategy] || :cookie
      end

      def active?
        # TODO: just touch a feature flag
        # Temporary change, we will change `experiment_percentage` in future to `Feature.enabled?
        Feature.enabled?(feature_flag_name, type: :experiment, default_enabled: :yaml)

        ::Gitlab.dev_env_or_com? && experiment_percentage > 0
      end

      def enabled_for_index?(index)
        return false if index.blank?

        index <= experiment_percentage
      end

      private

      def experiment_percentage
        feature_flag.percentage_of_time_value
      end

      def feature_flag
        Feature.get(feature_flag_name) # rubocop:disable Gitlab/AvoidFeatureGet
      end

      def feature_flag_name
        :"#{key}#{FEATURE_FLAG_SUFFIX}"
      end
    end
  end
end
