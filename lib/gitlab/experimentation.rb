# frozen_string_literal: true

# == Experimentation
#
# Utility module used for A/B testing experimental features. Define your experiments in the `EXPERIMENTS` constant.
# The feature_toggle and environment keys are optional. If the feature_toggle is not set, a feature with the name of
# the experiment will be checked, with a default value of true. The enabled_ratio is required and should be
# the ratio for the number of users for which this experiment is enabled. For example: a ratio of 0.1 will
# enable the experiment for 10% of the users (determined by the `experimentation_subject_index`).
#
module Gitlab
  module Experimentation
    EXPERIMENTS = {
      signup_flow: {
        feature_toggle: :experimental_separate_sign_up_flow,
        environment: ::Gitlab.dev_env_or_com?,
        enabled_ratio: 0.5,
        tracking_category: 'Growth::Acquisition::Experiment::SignUpFlow'
      }
    }.freeze

    # Controller concern that checks if an experimentation_subject_id cookie is present and sets it if absent.
    # Used for A/B testing of experimental features. Exposes the `experiment_enabled?(experiment_name)` method
    # to controllers and views. It returns true when the experiment is enabled and the user is selected as part
    # of the experimental group.
    #
    module ControllerConcern
      extend ActiveSupport::Concern

      included do
        before_action :set_experimentation_subject_id_cookie
        helper_method :experiment_enabled?
      end

      def set_experimentation_subject_id_cookie
        return if cookies[:experimentation_subject_id].present?

        cookies.permanent.signed[:experimentation_subject_id] = {
          value: SecureRandom.uuid,
          domain: :all,
          secure: ::Gitlab.config.gitlab.https,
          httponly: true
        }
      end

      def experiment_enabled?(experiment_key)
        Experimentation.enabled_for_user?(experiment_key, experimentation_subject_index) || forced_enabled?(experiment_key)
      end

      def track_experiment_event(experiment_key, action)
        track_experiment_event_for(experiment_key, action) do |tracking_data|
          ::Gitlab::Tracking.event(tracking_data.delete(:category), tracking_data.delete(:action), tracking_data)
        end
      end

      def frontend_experimentation_tracking_data(experiment_key, action)
        track_experiment_event_for(experiment_key, action) do |tracking_data|
          gon.push(tracking_data: tracking_data)
        end
      end

      private

      def experimentation_subject_id
        cookies.signed[:experimentation_subject_id]
      end

      def experimentation_subject_index
        return if experimentation_subject_id.blank?

        experimentation_subject_id.delete('-').hex % 100
      end

      def track_experiment_event_for(experiment_key, action)
        return unless Experimentation.enabled?(experiment_key)

        yield experimentation_tracking_data(experiment_key, action)
      end

      def experimentation_tracking_data(experiment_key, action)
        {
          category: tracking_category(experiment_key),
          action: action,
          property: tracking_group(experiment_key),
          label: experimentation_subject_id
        }
      end

      def tracking_category(experiment_key)
        Experimentation.experiment(experiment_key).tracking_category
      end

      def tracking_group(experiment_key)
        return unless Experimentation.enabled?(experiment_key)

        experiment_enabled?(experiment_key) ? 'experimental_group' : 'control_group'
      end

      def forced_enabled?(experiment_key)
        params.has_key?(:force_experiment) && params[:force_experiment] == experiment_key.to_s
      end
    end

    class << self
      def experiment(key)
        Experiment.new(EXPERIMENTS[key].merge(key: key))
      end

      def enabled?(experiment_key)
        return false unless EXPERIMENTS.key?(experiment_key)

        experiment = experiment(experiment_key)
        experiment.feature_toggle_enabled? && experiment.enabled_for_environment?
      end

      def enabled_for_user?(experiment_key, experimentation_subject_index)
        enabled?(experiment_key) &&
          experiment(experiment_key).enabled_for_experimentation_subject?(experimentation_subject_index)
      end
    end

    Experiment = Struct.new(:key, :feature_toggle, :environment, :enabled_ratio, :tracking_category, keyword_init: true) do
      def feature_toggle_enabled?
        return Feature.enabled?(key, default_enabled: true) if feature_toggle.nil?

        Feature.enabled?(feature_toggle)
      end

      def enabled_for_environment?
        return true if environment.nil?

        environment
      end

      def enabled_for_experimentation_subject?(experimentation_subject_index)
        return false if enabled_ratio.nil? || experimentation_subject_index.blank?

        experimentation_subject_index <= enabled_ratio * 100
      end
    end
  end
end
