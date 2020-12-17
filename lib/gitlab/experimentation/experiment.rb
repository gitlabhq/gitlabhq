# frozen_string_literal: true

module Gitlab
  module Experimentation
    class Experiment
      FEATURE_FLAG_SUFFIX = "_experiment_percentage"

      attr_reader :key, :tracking_category, :use_backwards_compatible_subject_index

      def initialize(key, **params)
        @key = key
        @tracking_category = params[:tracking_category]
        @use_backwards_compatible_subject_index = params[:use_backwards_compatible_subject_index]

        @experiment_percentage = Feature.get(:"#{key}#{FEATURE_FLAG_SUFFIX}").percentage_of_time_value # rubocop:disable Gitlab/AvoidFeatureGet
      end

      def active?
        ::Gitlab.dev_env_or_com? && experiment_percentage > 0
      end

      def enabled_for_index?(index)
        return false if index.blank?

        index <= experiment_percentage
      end

      private

      attr_reader :experiment_percentage
    end
  end
end
